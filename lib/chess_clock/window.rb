# frozen_string_literal: true

require "gtk4"
require "adwaita"

require_relative "settings"
require_relative "primary_menu"
require_relative "shortcuts_window"
require_relative "time_control_entry"
require_relative "timer_button"
require_relative "state_machine"
require_relative "increment_state_machine"
require_relative "bronstein_state_machine"
require_relative "delay_state_machine"

module ChessClock
  # Window is the application window: a stack holding the two screens the app
  # has, and the actions both of them reach for.
  #
  # Ported from src/window.py and src/gtk/window.ui. The setup screen is a
  # window handle (so the whole surface drags the window) over the time control
  # entry, the method chooser and a Start Game button. The timer screen is an
  # overlay: the two clock faces fill it, and the window controls, the menu
  # button, the play/pause button and a headerbar that fades in on pointer
  # motion float on top — a clock is read from across a table, so nothing
  # permanent is allowed to take space from the digits.
  #
  # A breakpoint handles narrow and portrait windows: the faces stack, the two
  # floating buttons move to the sides, and the A face turns 180° so the player
  # sitting opposite reads their own clock the right way up.
  #
  # The window keeps one state machine at a time. Starting a game throws the
  # old one away and builds the one the chosen method asks for, which is why
  # StateMachine#disconnect_all exists: the buttons outlive the machine driving
  # them. Upstream also installs the timers' frame-clock callbacks here; in
  # this port each Timer installs its own when it starts running, so there is
  # one callback per running clock instead of two per game.
  class Window
    TITLE = "Chess Clock"
    SETUP = "setup"
    TIMER = "timer"
    MINIMUM_WIDTH = 360
    MINIMUM_HEIGHT = 294
    NARROW_CONDITION = "max-aspect-ratio: 1/1 or max-width: 520px"

    # The five-minute, no-increment game upstream opens on, before the player
    # has chosen anything.
    DEFAULT_TIME = 300
    DEFAULT_INCREMENT = 0

    # The order of upstream's method_chooser model, so the chooser's index is
    # the rule.
    METHODS = [
      IncrementStateMachine,
      BronsteinStateMachine,
      DelayStateMachine,
    ].freeze

    CONTROL_METHOD_NAMES = [
      "Increment",
      "Bronstein delay",
      "Simple delay",
    ].freeze

    ACCELERATORS = {
      "new"               => ["<primary>n"],
      "restart"           => ["<primary>r"],
      "close"             => ["<primary>w"],
      "menu"              => ["F10"],
      "show-help-overlay" => ["<primary>question"],
    }.freeze

    attr_reader :settings, :state_machine

    def initialize(app, settings: nil)
      @app = app
      @settings = settings || Settings.new
    end

    def build
      window.tap do |win|
        win.content = main_stack
        win.add_breakpoint(narrow_breakpoint)

        install_actions

        main_stack.tap do |stack|
          stack.add_named(control_chooser, SETUP)
          stack.add_named(timer_screen, TIMER)

          control_chooser.tap do |handle|
            handle.child = setup_toolbar

            setup_toolbar.tap do |view|
              view.add_top_bar(setup_header)
              view.content = setup_scroll

              setup_scroll.tap do |scroll|
                scroll.child = setup_box

                setup_box.tap do |box|
                  box.append(welcome_box)
                  box.append(preferences_group)
                  box.append(start_game)

                  welcome_box.tap do |welcome|
                    welcome.append(welcome_title)
                    welcome.append(welcome_subtitle)
                  end

                  preferences_group.tap do |group|
                    group.add(custom_control_row)
                    group.add(method_chooser)

                    custom_control_row.child = custom_control.build
                    @settings.bind_combo_row("control-method", method_chooser)
                  end

                  start_game.signal_connect("clicked") { on_start_game }
                end
              end
            end
          end

          timer_screen.tap do |overlay|
            overlay.child = timer_box
            overlay.add_overlay(headerbar_box)
            overlay.add_overlay(windowcontrols_start)
            overlay.add_overlay(windowcontrols_start_end)
            overlay.add_overlay(windowcontrols_end)
            overlay.add_overlay(main_menu)
            overlay.add_overlay(play_pause)

            timer_box.tap do |box|
              box.append(a_timer.build)
              box.append(b_timer.build)
            end

            headerbar_box.tap do |box|
              box.append(headerbar_revealer)

              headerbar_revealer.tap do |revealer|
                revealer.child = timer_header
                revealer.add_controller(headerbar_motion)

                headerbar_motion.tap do |motion|
                  motion.signal_connect("enter") { reveal_headerbar }
                  motion.signal_connect("motion") { reveal_headerbar }
                  motion.signal_connect("leave") { hide_headerbar }
                end
              end
            end

            main_menu.menu_model = primary_menu.build

            # Reads the machine at click time, so swapping machines needs no
            # reconnection here.
            play_pause.signal_connect("clicked") { @state_machine.on_pause_clicked }
          end

          narrow_breakpoint.tap do |breakpoint|
            breakpoint.signal_connect("apply") { apply_narrow }
            breakpoint.signal_connect("unapply") { unapply_narrow }
          end

          stack.visible_child_name = SETUP
        end

        link_state_machine(IncrementStateMachine.new(win, DEFAULT_TIME, DEFAULT_INCREMENT))

        # Again now the faces are connected, so they show the default game's
        # time rather than a zeroed clock.
        @state_machine.state = StateMachine::START
      end
    end

    def present
      window.present
    end

    # --- The state machine ----------------------------------------------------

    def link_state_machine(machine)
      @state_machine = machine
      machine.muted = @settings["muted"]
      machine.add_a_button(a_timer)
      machine.add_b_button(b_timer)
      @machine_handler_ids = [
        machine.connect(:pause, method(:on_pause)),
        machine.connect(:awbb, method(:on_awbb)),
        machine.connect(:abbw, method(:on_abbw)),
      ]
    end

    def unlink_state_machine
      @state_machine.then do |machine|
        if machine
          @machine_handler_ids.each { |id| machine.disconnect(id) }
          machine.disconnect_all
        end
      end
    end

    # --- Action callbacks -----------------------------------------------------

    # Back to the setup screen, scrolled to the top, with the headerbar out.
    def on_new_action
      main_stack.visible_child_name = SETUP
      setup_scroll.vadjustment.value = 0
      headerbar_revealer.reveal_child = true
    end

    def on_restart_action
      @state_machine.state = StateMachine::START
    end

    # F10 opens the menu, but only on the screen the menu button is on.
    def on_menu_popup
      if main_stack.visible_child_name == TIMER
        main_menu.popup
      end
    end

    def on_start_game
      custom_control.control.then do |(time, increment)|
        unlink_state_machine
        link_state_machine(machine_class.new(window, time, increment))
        @state_machine.state = StateMachine::START
        main_stack.visible_child_name = TIMER
        headerbar_revealer.reveal_child = false
      end
    end

    def machine_class = METHODS.fetch(method_chooser.selected, IncrementStateMachine)

    # The mute toggle is stateful: activating it flips the state, and the
    # change-state handler is the one place the new value is written down.
    def toggle_muted(action)
      @state_machine.muted = !action.state.value
      action.change_state(GLib::Variant.new(@state_machine.muted))
    end

    def change_muted(action, new_state)
      action.state = new_state
      @settings["muted"] = new_state.value
      @state_machine.muted = new_state.value
    end

    # --- State machine signal handlers ----------------------------------------

    def on_pause(_machine, active, paused)
      play_pause.sensitive = active
      if paused
        play_pause.icon_name = "media-playback-start-symbolic"
      else
        play_pause.icon_name = "media-playback-pause-symbolic"
      end
    end

    # The window controls sit on the players' halves, so they take the colour
    # of the half under them.
    def on_awbb(*_args)
      paint_controls("white", "black")
    end

    def on_abbw(*_args)
      paint_controls("black", "white")
    end

    def reveal_headerbar(*_args)
      headerbar_revealer.reveal_child = true
    end

    def hide_headerbar(*_args)
      headerbar_revealer.reveal_child = false
    end

    # --- Breakpoint -----------------------------------------------------------

    def apply_narrow
      timer_box.orientation = :vertical
      main_menu.halign = :end
      main_menu.valign = :center
      play_pause.halign = :start
      play_pause.valign = :center
      windowcontrols_start_end.visible = true
      windowcontrols_end.visible = false
      a_timer.inverted = true
    end

    def unapply_narrow
      timer_box.orientation = :horizontal
      main_menu.halign = :center
      main_menu.valign = :start
      play_pause.halign = :center
      play_pause.valign = :end
      windowcontrols_start_end.visible = false
      windowcontrols_end.visible = true
      a_timer.inverted = false
    end

    # --- Widgets --------------------------------------------------------------

    def window
      @window ||= Adwaita::ApplicationWindow.new(@app).tap do |win|
        win.title = TITLE
        win.set_size_request(MINIMUM_WIDTH, MINIMUM_HEIGHT)
        @settings.apply_to(win)
      end
    end

    def main_stack
      @main_stack ||= Gtk::Stack.new.tap do |stack|
        stack.transition_type = :slide_left_right
      end
    end

    def narrow_breakpoint
      @narrow_breakpoint ||= Adwaita::Breakpoint.new(Adwaita::BreakpointCondition.parse(NARROW_CONDITION))
    end

    # --- The setup screen -----------------------------------------------------

    def control_chooser
      @control_chooser ||= Gtk::WindowHandle.new.tap do |handle|
        announce(handle, "Select time controls")
      end
    end

    def setup_toolbar = @setup_toolbar ||= Adwaita::ToolbarView.new
    def setup_header = @setup_header ||= Adwaita::HeaderBar.new

    def setup_scroll
      @setup_scroll ||= Gtk::ScrolledWindow.new.tap do |scroll|
        scroll.hscrollbar_policy = :never
      end
    end

    def setup_box
      @setup_box ||= Gtk::Box.new(:vertical, 24).tap do |box|
        box.halign = :center
        box.valign = :center
        box.margin_top = 42
        box.margin_bottom = 36
        box.margin_start = 12
        box.margin_end = 12
      end
    end

    def welcome_box = @welcome_box ||= Gtk::Box.new(:vertical, 12)

    def welcome_title
      @welcome_title ||= Gtk::Label.new("Welcome to Chess Clock").tap do |label|
        label.valign = :center
        label.vexpand = false
        label.add_css_class("title-1")
      end
    end

    def welcome_subtitle
      @welcome_subtitle ||= Gtk::Label.new("Select time controls below to get started")
    end

    def preferences_group = @preferences_group ||= Adwaita::PreferencesGroup.new

    # Not activatable: the row is a container for the spin buttons and preset
    # buttons, and has nothing of its own to activate.
    def custom_control_row
      @custom_control_row ||= Adwaita::PreferencesRow.new.tap do |row|
        row.activatable = false
      end
    end

    def custom_control = @custom_control ||= TimeControlEntry.new(@settings)

    def method_chooser
      @method_chooser ||= Adwaita::ComboRow.new.tap do |row|
        row.title = "Time control method"
        row.model = Gtk::StringList.new(CONTROL_METHOD_NAMES)
      end
    end

    def start_game
      @start_game ||= Gtk::Button.new.tap do |button|
        button.label = "Start Game"
        button.halign = :center
        button.hexpand = false
        button.add_css_class("pill")
        button.add_css_class("suggested-action")
      end
    end

    # --- The timer screen -----------------------------------------------------

    def timer_screen = @timer_screen ||= Gtk::Overlay.new

    def timer_box
      @timer_box ||= Gtk::Box.new(:horizontal, 0).tap do |box|
        box.homogeneous = true
        box.add_css_class("linked")
      end
    end

    def a_timer = @a_timer ||= TimerButton.new(:white)
    def b_timer = @b_timer ||= TimerButton.new(:black)

    def headerbar_box
      @headerbar_box ||= Gtk::Box.new(:vertical, 0).tap do |box|
        box.valign = :start
      end
    end

    def headerbar_revealer
      @headerbar_revealer ||= Gtk::Revealer.new.tap do |revealer|
        revealer.reveal_child = true
        revealer.transition_type = :crossfade
        revealer.overflow = :visible
      end
    end

    # Transparent: it is there for the window controls and the drag area, not
    # to be seen over the clock faces.
    def timer_header
      @timer_header ||= Adwaita::HeaderBar.new.tap do |header|
        header.overflow = :visible
        header.valign = :start
        header.add_css_class("transparent")
      end
    end

    def headerbar_motion = @headerbar_motion ||= Gtk::EventControllerMotion.new

    def windowcontrols_start
      @windowcontrols_start ||= window_controls(:start).tap do |controls|
        controls.halign = :start
        controls.margin_start = 6
        controls.add_css_class("white")
      end
    end

    # The end-side controls for a stacked layout, where the window's end is the
    # bottom and the close button has to stay at the top instead.
    def windowcontrols_start_end
      @windowcontrols_start_end ||= window_controls(:end).tap do |controls|
        controls.halign = :end
        controls.margin_end = 6
        controls.visible = false
        controls.add_css_class("white")
      end
    end

    def windowcontrols_end
      @windowcontrols_end ||= window_controls(:end).tap do |controls|
        controls.halign = :end
        controls.margin_end = 6
        controls.add_css_class("black")
      end
    end

    def primary_menu = @primary_menu ||= PrimaryMenu.new
    def shortcuts_window = @shortcuts_window ||= ShortcutsWindow.new

    def main_menu
      @main_menu ||= Gtk::MenuButton.new.tap do |button|
        button.halign = :center
        button.valign = :start
        button.icon_name = "open-menu-symbolic"
        button.tooltip_text = "Main Menu"
        floating(button)
      end
    end

    def play_pause
      @play_pause ||= Gtk::Button.new.tap do |button|
        button.halign = :center
        button.valign = :end
        button.icon_name = "media-playback-pause-symbolic"
        button.tooltip_text = "Toggle Pause"
        button.add_css_class("large")
        floating(button)
      end
    end

    def mute_action
      @mute_action ||= Gio::SimpleAction.new("muted", nil, GLib::Variant.new(@settings["muted"]))
    end

    private

      def install_actions
        ACCELERATORS.each { |name, accelerators| create_action(name, accelerators) }

        mute_action.tap do |action|
          action.signal_connect("activate") { |act, _parameter| toggle_muted(act) }
          action.signal_connect("change-state") { |act, state| change_muted(act, state) }
          window.add_action(action)
        end
      end

      def create_action(name, accelerators)
        Gio::SimpleAction.new(name).tap do |action|
          action.signal_connect("activate") { activate(name) }
          window.add_action(action)
          @app&.set_accels_for_action("win.#{name}", accelerators)
        end
      end

      def activate(name)
        case name
        when "new" then on_new_action
        when "restart" then on_restart_action
        when "close" then window.close
        when "menu" then on_menu_popup
        when "show-help-overlay" then shortcuts_window.present(window)
        end
      end

      def paint_controls(start_colour, end_colour)
        [windowcontrols_start, windowcontrols_start_end].each do |controls|
          controls.add_css_class(start_colour)
          controls.remove_css_class(end_colour)
        end
        windowcontrols_end.add_css_class(end_colour)
        windowcontrols_end.remove_css_class(start_colour)
      end

      def window_controls(side)
        Gtk::WindowControls.new.tap do |controls|
          controls.side = side
          controls.valign = :start
          controls.margin_top = 6
        end
      end

    # The round, translucent treatment the floating buttons share.
      def floating(button)
        button.margin_top = 6
        button.margin_bottom = 6
        button.margin_start = 6
        button.margin_end = 6
        button.add_css_class("image-button")
        button.add_css_class("circular")
        button.add_css_class("osd")
      end

      def announce(widget, label)
        widget.update_property(
          [Gtk::AccessibleProperty::LABEL],
          [GLib::Value.new(GLib::Type::STRING, label)],
        )
      end
  end
end
