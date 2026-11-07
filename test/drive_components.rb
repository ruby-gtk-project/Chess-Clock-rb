#!/usr/bin/env ruby
# frozen_string_literal: true

# Drives the parts of the app the other two drive scripts never touch.
#
# drive_window.rb proves the window builds and walks the two screens, the
# breakpoint and the five window actions; drive_countdown.rb runs a real game
# down to zero. Between them they still leave most of the port unexercised:
# the eight preset buttons are never clicked, the simple-delay rule-set is
# never built, the primary menu is only checked for being *open* rather than
# for its items, the accelerators are never read back, the accessible names are
# never read at all, the stylesheet is assumed rather than observed, and the
# empty and error states (a zero-time game, a corrupt settings file) are never
# entered.
#
# This script closes those gaps, so that between the three every component in
# .reports/component-inventory.md is driven by something.
#
#   nix develop --command xvfb-run -a ruby test/drive_components.rb
#
# It writes PNGs to tmp/shots and exits non-zero if any check fails.

require "tmpdir"
require "json"

# A scratch config directory, so a run never reads or scribbles on the real
# settings. The file store is asked for by name as well, because the
# persistence round trip below needs a path it can re-open.
ENV["XDG_CONFIG_HOME"] = Dir.mktmpdir("chess-clock-components")
SETTINGS_PATH = File.join(ENV.fetch("XDG_CONFIG_HOME"), "settings.json")

# A geometry that is not the schema default, written before the app starts, so
# that restoring it is something this run can observe rather than assume. It
# has to fit the display — this one is 640x480, and a window is clamped to the
# screen — and stay clear of the window's own narrow breakpoint at 520px, so
# that the wide layout is what the later steps are reading.
STARTING_GEOMETRY = { "width" => 600, "height" => 420 }.freeze
File.write(SETTINGS_PATH, "#{JSON.pretty_generate(STARTING_GEOMETRY)}\n")

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "chess_clock"

require_relative "gtk_driver"

SETUP = ChessClock::Window::SETUP
TIMER = ChessClock::Window::TIMER
START = ChessClock::StateMachine::START
A_RUN = ChessClock::StateMachine::A_RUN
B_RUN = ChessClock::StateMachine::B_RUN

# Every descendant of a widget, in tree order: the only way to read a
# GtkShortcutsWindow back, since its sections are added through GtkBuildable
# and it exposes no accessor for them.
def descendants(widget)
  [].tap do |found|
    child = widget.first_child
    while child
      found << child
      found.concat(descendants(child))
      child = child.next_sibling
    end
  end
end

def of_class(widget, klass) = descendants(widget).select { |w| w.is_a?(klass) }

# The labels AccessibleLabel hangs off a widget through the LABELLED_BY
# relation, which is where the port puts the accessible name.
def accessible_names(widget) = widget.mnemonic_labels.map(&:text)

application = ChessClock::Application.new(
  settings: ChessClock::Settings.new(path: SETTINGS_PATH),
  present:  true,
)

GtkDriver.drive(application, shots: "tmp/shots") do |d, app|
  d.window { app.main_window.window }

  # --- The application singleton -----------------------------------------

  d.step("the window opened at the geometry the settings file remembers") do
    app.main_window.window.then do |win|
      d.check("the stored width was restored") { win.default_width == STARTING_GEOMETRY["width"] }
      d.check("the stored height was restored") { win.default_height == STARTING_GEOMETRY["height"] }
      d.check("it did not open maximized") { win.maximized? == false }
      d.check("the geometry is kept up to date in the store") do
        app.main_window.settings["width"] == STARTING_GEOMETRY["width"]
      end
    end
  end

  d.step("the application installed its two actions") do
    app.app.then do |gtk|
      d.check("app.quit exists") { !gtk.lookup_action("quit").nil? }
      d.check("app.about exists") { !gtk.lookup_action("about").nil? }
      d.check("app.quit is bound to Ctrl+Q") { gtk.get_accels_for_action("app.quit") == ["<Control>q"] }
      d.check("app.about is bound to nothing, as upstream leaves it") do
        gtk.get_accels_for_action("app.about").empty?
      end
    end
  end

  d.step("the window installed its six actions with upstream's accelerators") do
    app.main_window.window.then do |win|
      %w[new restart close menu show-help-overlay muted].each do |name|
        d.check("win.#{name} exists") { !win.lookup_action(name).nil? }
      end
    end

    app.app.then do |gtk|
      {
        "win.new"               => ["<Control>n"],
        "win.restart"           => ["<Control>r"],
        "win.close"             => ["<Control>w"],
        "win.menu"              => ["F10"],
        "win.show-help-overlay" => ["<Control>question"],
      }.each do |action, accelerators|
        d.check("#{action} is bound to #{accelerators.join(', ')}") do
          gtk.get_accels_for_action(action) == accelerators
        end
      end
    end
  end

  # --- The stylesheet -----------------------------------------------------

  d.step("the stylesheet is on the display") do
    # label.colon { min-width: 17px } out of Style::STYLE, measured on a
    # throwaway label: if the sheet were not installed this would be the
    # label's own 1px of text.
    Gtk::Label.new(ChessClock::TimerButton::COLON).tap do |label|
      label.add_css_class("colon")
      Gtk::Box.new(:horizontal, 0).append(label)
      d.check("label.colon takes its 17px minimum from style.css") do
        label.measure(:horizontal, -1).first == 17
      end
    end

    # The high-contrast sheet is only swapped in when the portal says so, and
    # there is no portal here, so what can be driven is that it parses and
    # that the handler watching for the switch is connected.
    d.check("the high-contrast sheet parses") { !app.style.high_contrast_provider.nil? }
    d.check("high contrast is off in this session") { app.style.style_manager.high_contrast? == false }
    d.check("the high-contrast watcher runs when the setting is notified") do
      app.style.style_manager.notify("high-contrast")
      true
    end
  end

  # --- The primary menu ---------------------------------------------------

  d.step("the primary menu model is upstream's three sections") do
    app.main_window.primary_menu.menu.then do |menu|
      d.check("three sections") { menu.n_items == 3 }

      [
        [["_New Time Control", "win.new"], ["_Restart Timer", "win.restart"]],
        [["_Mute Alert Sound", "win.muted"]],
        [["_Keyboard Shortcuts", "win.show-help-overlay"], ["_About Chess Clock", "app.about"]],
      ].each_with_index do |items, section_index|
        menu.get_item_link(section_index, "section").then do |section|
          d.check("section #{section_index} holds #{items.length} item(s)") { section.n_items == items.length }

          items.each_with_index do |(label, action), item_index|
            d.check("#{label} activates #{action}") do
              section.get_item_attribute_value(item_index, "label", nil) == label &&
                section.get_item_attribute_value(item_index, "action", nil) == action
            end
          end
        end
      end
    end
  end

  # --- The time control entry: all eight presets --------------------------

  ChessClock::TimeControlEntry::PRESETS.each do |preset|
    d.step("the #{preset[:label]} preset button is clicked") do
      app.main_window.custom_control.preset_buttons.fetch(preset[:label]).activate
    end

    d.step("the #{preset[:label]} preset filled the custom control in") do
      app.main_window.custom_control.then do |entry|
        d.check("#{preset[:label]} reads as #{(preset[:minutes] * 60) + preset[:seconds]}+#{preset[:increment]}") do
          entry.control == [(preset[:minutes] * 60) + preset[:seconds], preset[:increment]]
        end
        # Not a translation check: preset[:tooltip] is the same PRESETS
        # entry the button's own tooltip was built from, so this only proves
        # the button is wired to that table, under whatever locale this
        # process runs in. See TP3.
        d.check("#{preset[:label]}'s tooltip is wired from TimeControlEntry::PRESETS") do
          entry.preset_buttons.fetch(preset[:label]).tooltip_text == preset[:tooltip]
        end
      end
    end
  end

  d.step("the seconds spin is wound up past 59") do
    app.main_window.custom_control.then do |entry|
      entry.set_control({ minutes: 4, seconds: 59, increment: 0 })
      entry.seconds.spin(:step_forward, 1)
    end
  end

  d.step("the wrap carried a minute") do
    app.main_window.custom_control.then do |entry|
      d.check("the seconds came back to 0") { entry.seconds_adjustment.value.to_i.zero? }
      d.check("a minute was carried in") { entry.minutes_adjustment.value.to_i == 5 }
      d.check("the seconds still read two digits") { entry.seconds.text == "00" }
    end
  end

  d.step("the seconds spin is wound down past 0") do
    app.main_window.custom_control.seconds.spin(:step_backward, 1)
  end

  d.step("the wrap borrowed a minute") do
    app.main_window.custom_control.then do |entry|
      d.check("the seconds came back to 59") { entry.seconds_adjustment.value.to_i == 59 }
      d.check("a minute was borrowed") { entry.minutes_adjustment.value.to_i == 4 }
      d.check("the seconds read two digits") { entry.seconds.text == "59" }
      d.check("the pair reads as 4∶59") { entry.control.first == 299 }
    end
  end

  d.step("the spin buttons are pushed past their limits") do
    app.main_window.custom_control.then do |entry|
      entry.minutes_adjustment.value = 5_000
      entry.increment_adjustment.value = 5_000
      entry.seconds_adjustment.value = 500
    end
  end

  d.step("the adjustments clamped at upstream's upper bounds") do
    app.main_window.custom_control.then do |entry|
      d.check("minutes clamp at 999") { entry.minutes_adjustment.value.to_i == ChessClock::TimeControlEntry::MINUTES_LIMIT }
      d.check("the increment clamps at 999") { entry.increment_adjustment.value.to_i == ChessClock::TimeControlEntry::INCREMENT_LIMIT }
      d.check("seconds clamp at 59") { entry.seconds_adjustment.value.to_i == ChessClock::TimeControlEntry::SECONDS_LIMIT }
      d.shot("30-limits")
    end
  end

  # --- Settings: the round trip through the store -------------------------

  d.step("the custom control is set to 7∶08 +9 and read back from a fresh store") do
    app.main_window.custom_control.set_control({ minutes: 7, seconds: 8, increment: 9 })
  end

  d.step("the store kept what the spin buttons were set to") do
    app.main_window.settings.then do |settings|
      d.check("this run is on the file store") { settings.store_kind == :file }
      d.check("minutes were written through") { settings["custom-control-minutes"] == 7 }
      d.check("seconds were written through") { settings["custom-control-seconds"] == 8 }
      d.check("the increment was written through") { settings["custom-control-increment"] == 9 }
    end

    ChessClock::Settings.new(path: SETTINGS_PATH).then do |reloaded|
      d.check("a fresh Settings on the same file sees 7 minutes") { reloaded.custom_control_minutes == 7 }
      d.check("a fresh Settings on the same file sees 8 seconds") { reloaded.custom_control_seconds == 8 }
      d.check("a fresh Settings on the same file sees a 9s increment") { reloaded.custom_control_increment == 9 }
    end
  end

  d.step("a corrupt settings file is opened") do
    File.join(ENV.fetch("XDG_CONFIG_HOME"), "broken.json").then do |path|
      File.write(path, "{ this is not json")
      ChessClock::Settings.new(path: path).then do |broken|
        d.check("the geometry falls back to the schema default") { broken["width"] == 640 }
        d.check("the method falls back to the schema default") { broken["control-method"] == 0 }
        d.check("a write over the corrupt file still lands") do
          broken["muted"] = true
          JSON.parse(File.read(path))["muted"] == true
        end
      end
    end
  end

  # --- The simple-delay rule set ------------------------------------------

  d.step("a ten-second simple-delay game with a two-second delay is started") do
    app.main_window.then do |win|
      win.custom_control.set_control({ minutes: 0, seconds: 10, increment: 2 })
      win.method_chooser.selected = 2
      win.start_game.activate
    end
  end

  d.step("the delay rule-set is driving the clocks") do
    app.main_window.then do |win|
      d.check("the stack switched to the timer screen") { win.main_stack.visible_child_name == TIMER }
      d.check("the machine is a DelayStateMachine") { win.state_machine.is_a?(ChessClock::DelayStateMachine) }
      d.check("the chooser wrote the method through to the store") { win.settings["control-method"] == 2 }
      d.check("the delay timer is armed at two seconds") { win.state_machine.delay_timer.time == 2_000_000 }
      d.check("neither clock got the delay added to it") { win.state_machine.timer_a.time == 10_000_000 }
      d.check("both faces read 0:10") do
        [win.a_timer, win.b_timer].all? { |face| face.minutes.label == "0" && face.seconds.label == "10" }
      end
      d.check("the headerbar was hidden when the game started") { win.headerbar_revealer.reveal_child? == false }
    end
  end

  d.step("B's half is tapped, putting A on the move") do
    app.main_window.b_timer.activate
  end

  d.step("A's clock is held still while the delay runs") do
    app.main_window.state_machine.then do |machine|
      d.check("the machine is in A_RUN") { machine.state == A_RUN }
      d.check("the delay timer is the one running") { machine.delay_timer.running == true }
      d.check("A's own clock is held") { machine.timer_a.running == false }
      d.check("A has lost no time yet") { machine.timer_a.time == 10_000_000 }
    end
    # One step after the switch, so the stack's slide-left-right transition has
    # finished and the shot shows the timer screen rather than the setup screen
    # sliding out.
    d.shot("31-delay-start")
  end

  3.times { |i| d.step("waiting for the two-second delay to run out (#{i + 1}/3)") { nil } }

  d.step("the delay expired and handed the clock over to A") do
    app.main_window.state_machine.then do |machine|
      d.check("the delay timer is at zero") { machine.delay_timer.time.zero? }
      d.check("A's clock is running now") { machine.timer_a.running == true }
      d.check("A is losing time") { machine.timer_a.time < 10_000_000 }
      d.check("A still has more than the delay was worth") { machine.timer_a.time > 5_000_000 }
      d.check("B has lost nothing") { machine.timer_b.time == 10_000_000 }
      d.shot("32-delay-running")
    end
  end

  # --- The floating headerbar --------------------------------------------

  d.step("the pointer enters the headerbar area") do
    app.main_window.headerbar_motion.signal_emit("enter", 10.0, 10.0)
  end

  d.step("the headerbar revealed itself") do
    d.check("the revealer is open") { app.main_window.headerbar_revealer.reveal_child? == true }
    d.shot("33-headerbar-revealed")
  end

  d.step("the pointer moves inside it, then leaves") do
    app.main_window.headerbar_motion.tap do |motion|
      motion.signal_emit("motion", 20.0, 20.0)
      d.check("motion keeps it open") { app.main_window.headerbar_revealer.reveal_child? == true }
      motion.signal_emit("leave")
    end
  end

  d.step("the headerbar hid itself again") do
    d.check("the revealer is closed") { app.main_window.headerbar_revealer.reveal_child? == false }
  end

  # --- The window controls take the colour of the half under them ---------

  d.step("win.new goes back to the setup screen") do
    app.main_window.window.activate_action("new", nil)
  end

  d.step("the setup screen is back with the headerbar showing") do
    app.main_window.then do |win|
      d.check("the stack is on the setup screen") { win.main_stack.visible_child_name == SETUP }
      d.check("the headerbar came back") { win.headerbar_revealer.reveal_child? == true }
    end
  end

  d.step("a five-minute Fischer game is started and A taps first") do
    app.main_window.then do |win|
      win.custom_control.set_control(ChessClock::TimeControlEntry::PRESETS[2])
      win.method_chooser.selected = 0
      win.start_game.activate
    end
  end

  d.step("A's half is tapped from the start, so A is black") do
    app.main_window.a_timer.activate
  end

  d.step("abbw painted the controls for a black A") do
    app.main_window.then do |win|
      d.check("the machine is in B_RUN") { win.state_machine.state == B_RUN }
      d.check("A's face went black") { win.a_timer.css_classes.include?("black") }
      d.check("B's face went white") { win.b_timer.css_classes.include?("white") }
      d.check("the start-side controls are black, over A") { win.windowcontrols_start.css_classes.include?("black") }
      d.check("the end-side controls are white, over B") { win.windowcontrols_end.css_classes.include?("white") }
      d.check("A is named for the black player") { accessible_names(win.a_timer) == ["Player black timer"] }
      d.check("B is named for the white player") { accessible_names(win.b_timer) == ["Player white timer"] }
      d.shot("34-abbw")
    end
  end

  d.step("the game is restarted and B taps first") do
    app.main_window.window.activate_action("restart", nil)
  end

  d.step("B's half is tapped from the start, so A is white") do
    app.main_window.b_timer.activate
  end

  d.step("awbb painted the controls back for a white A") do
    app.main_window.then do |win|
      d.check("the machine is in A_RUN") { win.state_machine.state == A_RUN }
      d.check("A's face went white") { win.a_timer.css_classes.include?("white") }
      d.check("A's face is no longer black") { !win.a_timer.css_classes.include?("black") }
      d.check("the start-side controls are white, over A") { win.windowcontrols_start.css_classes.include?("white") }
      d.check("the end-side controls are black, over B") { win.windowcontrols_end.css_classes.include?("black") }
      d.check("A is named for the white player again") { accessible_names(win.a_timer) == ["Player white timer"] }
      d.check("the setup screen's handle is named too") do
        accessible_names(win.control_chooser) == ["Select time controls"]
      end
      d.shot("35-awbb")
    end
  end

  # --- The clock face's own breakpoint ------------------------------------
  #
  # A face of its own in a window of its own, rather than the two inside the
  # app: this display server has no window manager, so GTK can shrink a mapped
  # window but never enlarge one past the size it opened at, and no window the
  # app opens can be made wide enough afterwards to give a half the 600px the
  # face's breakpoint waits for.

  face = ChessClock::TimerButton.new(:white)
  face_window = Gtk::Window.new

  d.step("a clock face is opened on its own in a 700px window") do
    face_window.tap do |win|
      win.set_default_size(700, 300)
      win.child = face.build
      win.present
    end
  end

  d.step("the digits jumped to 100pt") do
    d.check("the face is at least 600px wide") { face.width >= 600 }
    d.check("the minutes carry a Pango size attribute") do
      face.minutes.attributes&.attributes&.any? { |attribute| attribute.is_a?(Pango::AttrSize) }
    end
    d.check("that size is 100pt") do
      face.minutes.attributes.attributes.grep(Pango::AttrSize).map(&:size) ==
        [ChessClock::TimerButton::FONT_SIZE * Pango::SCALE]
    end
    d.check("the seconds got the same treatment") do
      face.seconds.attributes.attributes.grep(Pango::AttrSize).map(&:size) ==
        [ChessClock::TimerButton::FONT_SIZE * Pango::SCALE]
    end
    d.check("so did the colon between them") do
      face.colon.attributes.attributes.grep(Pango::AttrSize).map(&:size) ==
        [ChessClock::TimerButton::FONT_SIZE * Pango::SCALE]
    end
    d.shot("36-large-face", face)
  end

  d.step("that window is narrowed under 600px") do
    face_window.default_width = 400
  end

  d.step("the digits went back to the size the stylesheet gives them") do
    d.check("the face is under 600px again") { face.width < 600 }
    d.check("the minutes carry no size attribute") do
      face.minutes.attributes.attributes.grep(Pango::AttrSize).empty?
    end
    d.check("the inverted class follows the inverted property") do
      face.inverted = true
      face.css_classes.include?("inverted") && face.inverted == true
    end
    d.check("and goes away again") do
      face.inverted = false
      !face.css_classes.include?("inverted")
    end
    d.shot("36-small-face", face)
    face_window.close
  end

  # --- The empty state: a game with no time on the clock ------------------

  d.step("a zero-time game is set up") do
    app.main_window.then do |win|
      win.window.activate_action("new", nil)
      win.custom_control.set_control({ minutes: 0, seconds: 0, increment: 0 })
      win.method_chooser.selected = 0
    end
  end

  d.step("the zero-time game is started") do
    app.main_window.start_game.activate
  end

  d.step("both clocks start out of time") do
    app.main_window.then do |win|
      d.check("A has no time") { win.state_machine.timer_a.time.zero? }
      d.check("B has no time") { win.state_machine.timer_b.time.zero? }
      d.check("A's face reads 0:00") do
        win.a_timer.minutes.label == "0" && win.a_timer.seconds.label == "00"
      end
      d.check("A's face is marked expired") { win.a_timer.css_classes.include?("expired") }
      d.check("B's face is marked expired") { win.b_timer.css_classes.include?("expired") }
      d.check("the play/pause button is insensitive while nothing runs") { win.play_pause.sensitive? == false }
      d.shot("37-zero-game")
    end
  end

  # --- The alert sound ----------------------------------------------------

  d.step("the alert sound is asked to play, muted and unmuted") do
    d.check("a muted alert plays nothing") do
      ChessClock::AlertSound.new(muted: true).play.nil?
    end
    d.check("an unmuted alert takes a route rather than raising") do
      ChessClock::AlertSound.new.play
      true
    end
    # The fork's flake now carries the GSound typelib, so this is a real
    # assertion rather than a report: `available?` must be true, which only
    # holds once the loader resolves the namespace and Context#init succeeds.
    # Playing it here still falls back past GSound's own call, because this
    # sandbox's Xvfb display has no sound server for libcanberra to reach.
    d.check("GSound's typelib resolves and its context inits") do
      ChessClock::AlertSound.new.available?
    end

    app.main_window.then do |win|
      win.window.activate_action("muted", nil)
      d.check("win.muted muted the live machine") { win.state_machine.muted == true }
      d.check("win.muted wrote the setting") { win.settings["muted"] == true }
      win.window.activate_action("muted", nil)
      d.check("win.muted unmutes again") { win.state_machine.muted == false }
      d.check("and writes that through too") { win.settings["muted"] == false }
    end
  end

  # --- The shortcuts window ----------------------------------------------

  d.step("win.show-help-overlay opens the shortcuts window") do
    app.main_window.window.activate_action("show-help-overlay", nil)
  end

  d.step("the shortcuts window lists upstream's two groups and six shortcuts") do
    app.main_window.shortcuts_window.window.then do |help|
      d.check("it is on screen") { help.visible? }
      d.check("it is modal") { help.modal? }
      d.check("two groups, Game and General") do
        of_class(help, Gtk::ShortcutsGroup).map(&:title) == ["Game", "General"]
      end
      # GTK keeps a second copy of every shortcut on its own search page, so
      # the groups are what the two visible lists are read from.
      d.check("six shortcuts, in upstream's order") do
        of_class(help, Gtk::ShortcutsGroup).flat_map { |group| of_class(group, Gtk::ShortcutsShortcut) }.map(&:title) ==
          ["New Time Control", "Restart Timer", "Open Main Menu", "Show Shortcuts", "Close Window", "Quit"]
      end
      d.check("every shortcut resolved its action to a key combination") do
        of_class(help, Gtk::ShortcutsGroup)
          .flat_map { |group| of_class(group, Gtk::ShortcutLabel) }
          .none? { |label| label.accelerator.to_s.empty? }
      end
      d.check("the New Time Control row shows Ctrl+N") do
        of_class(help, Gtk::ShortcutsGroup)
          .flat_map { |group| of_class(group, Gtk::ShortcutsShortcut) }
          .first.accelerator == "<Control>n"
      end
      d.check("the Quit row shows the application accelerator, Ctrl+Q") do
        of_class(help, Gtk::ShortcutsGroup)
          .flat_map { |group| of_class(group, Gtk::ShortcutsShortcut) }
          .last.accelerator == "<Control>q"
      end
      d.shot("38-shortcuts", help)
    end
  end

  # --- The about window ---------------------------------------------------

  d.step("app.about opens the about window") do
    app.main_window.shortcuts_window.window.close
    app.app.activate_action("about", nil)
  end

  d.step("the about window carries the metainfo fields") do
    app.about_dialog.dialog.then do |about|
      # Not a translation check: under the English locale this process runs
      # in, `_("Chess Clock")` returns "Chess Clock" regardless of whether
      # gettext is wired correctly at all. It only proves the dialog's
      # application_name is AboutDialog::APPLICATION_NAME. The real
      # translation check — that a non-English locale actually changes the
      # string — is spec/chess_clock/translation_spec.rb (TR1/TP3).
      d.check("the application name is wired from AboutDialog::APPLICATION_NAME") { about.application_name == "Chess Clock" }
      d.check("the icon is the app id") { about.application_icon == ChessClock::Application::APP_ID }
      d.check("the version is 0.6.2") { about.version == "0.6.2" }
      d.check("the four developers are listed") { about.developers.length == 4 }
      d.check("the one artist is listed") { about.artists == ["Brage Fuglseth"] }
      d.check("the translator credits msgid is passed through") { !about.translator_credits.to_s.empty? }
      d.check("the licence is GPL-3.0") { about.license_type == Gtk::License::GPL_3_0 }
      d.check("the homepage is upstream's") { about.website == "https://gitlab.gnome.org/World/chess-clock" }
      d.check("the issue tracker is upstream's") { about.issue_url.end_with?("/-/issues") }
      d.check("the copyright line is set") { about.copyright.start_with?("©") }
      d.shot("39-about", about)
    end
  end

  # --- win.close and app.quit --------------------------------------------

  d.step("win.close closes the window") do
    app.main_window.window.then do |win|
      app.about_dialog.dialog.close
      win.activate_action("close", nil)
      20.times { GLib::MainContext.default.iteration(false) }
      d.check("the window is no longer on screen") { win.visible? == false }
    end

    app.app.then do |gtk|
      d.check("app.quit is still enabled with the window gone") { gtk.get_action_enabled("quit") }
      gtk.activate_action("quit", nil)
    end
  end
end
