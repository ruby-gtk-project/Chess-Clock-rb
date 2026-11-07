# frozen_string_literal: true

require "tmpdir"
require "chess_clock/application"

# Ported from src/window.py and src/gtk/window.ui — see window.rb's header.
# Built through a real ChessClock::Application rather than Window.new
# directly: Window needs a real Gtk::Application for
# `@app.set_accels_for_action` and a window to `inhibit`/`uninhibit` through
# its state machine, which application_spec.rb's own pattern already
# provides cheaply.
RSpec.describe ChessClock::Window do
  subject(:window) { application.main_window }

  # An explicit, per-example settings file: Settings.new with no path falls
  # back (no schema is installed in this dev shell) to one JSON file shared
  # by every caller that also omits a path, which would otherwise let one
  # example's control-method or muted write leak into the next through disk.
  let(:settings_path) { File.join(Dir.mktmpdir, "settings.json") }

  let(:application) do
    ChessClock::Application.new(
      app_id: "eu.fortysixandtwo.chessclock.spec#{object_id}",
      present: false,
      settings: ChessClock::Settings.new(path: settings_path),
    )
  end

  before do
    app = application.build
    app.register
    app.activate
  end

  describe "#build" do
    it "builds a two-page stack" do
      expect(window.main_stack.pages.n_items).to eq(2)
    end

    it "starts on the setup screen" do
      expect(window.main_stack.visible_child_name).to eq(ChessClock::Window::SETUP)
    end

    it "wires the primary menu's model onto the menu button" do
      expect(window.main_menu.menu_model).to equal(window.primary_menu.menu)
    end

    it "builds a default game already linked, so the faces show real time" do
      expect(window.state_machine.timer_a.time).to eq(ChessClock::Window::DEFAULT_TIME * 1_000_000)
    end
  end

  describe "the setup -> timer transition" do
    it "switches to the timer screen when the game starts" do
      window.on_start_game
      expect(window.main_stack.visible_child_name).to eq(ChessClock::Window::TIMER)
    end

    it "hides the headerbar revealer once a game has started" do
      window.headerbar_revealer.reveal_child = true
      window.on_start_game
      expect(window.headerbar_revealer.reveal_child?).to eq(false)
    end

    it "picks the increment machine by default" do
      window.on_start_game
      expect(window.state_machine).to be_a(ChessClock::IncrementStateMachine)
    end

    it "picks the machine named by the method chooser's selected index" do
      window.method_chooser.selected = 1
      window.on_start_game
      expect(window.state_machine).to be_a(ChessClock::BronsteinStateMachine)
    end

    it "returns to the setup screen scrolled to the top on the new action" do
      window.setup_scroll.vadjustment.value = 40
      window.on_new_action
      expect([window.main_stack.visible_child_name, window.setup_scroll.vadjustment.value]).to eq([ChessClock::Window::SETUP, 0.0])
    end
  end

  describe "#on_restart_action" do
    it "sends the live machine back to START" do
      window.state_machine.state = ChessClock::StateMachine::A_RUN
      window.on_restart_action
      expect(window.state_machine.state).to eq(ChessClock::StateMachine::START)
    end
  end

  describe "the mute action" do
    it "flips the state machine's muted flag and the action's own state on activation" do
      window.toggle_muted(window.mute_action)
      expect([window.state_machine.muted, window.mute_action.state]).to eq([true, true])
    end

    it "writes the new value to settings when the action's state changes" do
      window.change_muted(window.mute_action, GLib::Variant.new(true))
      expect([window.settings["muted"], window.state_machine.muted]).to eq([true, true])
    end
  end

  describe "#on_pause" do
    it "shows the pause icon while active and running" do
      window.on_pause(nil, true, false)
      expect([window.play_pause.sensitive?, window.play_pause.icon_name]).to eq([true, "media-playback-pause-symbolic"])
    end

    it "shows the play icon while active and paused" do
      window.on_pause(nil, true, true)
      expect([window.play_pause.sensitive?, window.play_pause.icon_name]).to eq([true, "media-playback-start-symbolic"])
    end

    it "makes the button insensitive while inactive" do
      window.on_pause(nil, false, false)
      expect(window.play_pause.sensitive?).to eq(false)
    end
  end

  describe "colouring the window controls to the side under them" do
    it "paints A's side white and B's side black on awbb" do
      window.on_awbb
      expect(
        [
          window.windowcontrols_start.css_classes.include?("white"),
          window.windowcontrols_end.css_classes.include?("black"),
        ],
      ).to eq([true, true])
    end

    it "paints A's side black and B's side white on abbw" do
      window.on_abbw
      expect(
        [
          window.windowcontrols_start.css_classes.include?("black"),
          window.windowcontrols_end.css_classes.include?("white"),
        ],
      ).to eq([true, true])
    end
  end

  describe "the headerbar revealer" do
    it "reveals on reveal_headerbar and hides on hide_headerbar" do
      window.hide_headerbar
      revealed_after_hide = window.headerbar_revealer.reveal_child?
      window.reveal_headerbar
      expect([revealed_after_hide, window.headerbar_revealer.reveal_child?]).to eq([false, true])
    end
  end

  describe "the narrow breakpoint" do
    # GtkWindowControls computes its own effective visibility from the
    # decoration layout (there is none under Xvfb), which shadows `visible?`
    # — so what is pinned here is the "visible" property Window itself wrote,
    # read back with `get_property` rather than through that override.
    it "stacks the faces, moves the floating buttons and inverts A on apply" do
      window.apply_narrow
      expect(
        [
          window.timer_box.orientation == :vertical,
          window.windowcontrols_start_end.get_property("visible"),
          window.windowcontrols_end.get_property("visible"),
          window.a_timer.inverted,
        ],
      ).to eq([true, true, false, true])
    end

    it "undoes all four on unapply" do
      window.apply_narrow
      window.unapply_narrow
      expect(
        [
          window.timer_box.orientation == :horizontal,
          window.windowcontrols_start_end.get_property("visible"),
          window.windowcontrols_end.get_property("visible"),
          window.a_timer.inverted,
        ],
      ).to eq([true, false, true, false])
    end
  end

  describe "actions and accelerators" do
    it "installs an action for every named accelerator" do
      ChessClock::Window::ACCELERATORS.each_key do |name|
        expect(window.window.lookup_action(name)).not_to be_nil
      end
    end

    it "installs the mute action" do
      expect(window.window.lookup_action("muted")).not_to be_nil
    end

    it "binds win.new to upstream's accelerator" do
      expect(application.app.get_accels_for_action("win.new")).to eq(["<Control>n"])
    end

    it "opens the shortcuts window on win.show-help-overlay" do
      window.window.activate_action("show-help-overlay", nil)
      expect(window.shortcuts_window.window.visible?).to eq(true)
    end
  end

  describe "#unlink_state_machine" do
    it "disconnects the outgoing machine so a dead machine cannot drive a live button" do
      old_machine = window.state_machine
      window.unlink_state_machine
      expect { old_machine.state = ChessClock::StateMachine::A_RUN }.not_to raise_error
      expect(window.a_timer.minutes.label).not_to be_nil
    end

    it "is safe to call before any machine has been linked" do
      bare = ChessClock::Window.new(application.app, settings: ChessClock::Settings.new(path: File.join(Dir.mktmpdir, "s.json")))
      expect { bare.unlink_state_machine }.not_to raise_error
    end
  end
end
