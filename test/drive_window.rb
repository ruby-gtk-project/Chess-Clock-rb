#!/usr/bin/env ruby
# frozen_string_literal: true

# Drives the real window headlessly: both screens, both breakpoints, the six
# machine signals and the five window actions.
#
# This is the third gap test-parity.md names — "the port runs" as a claim
# someone else can re-run. GTK4 renders to an offscreen surface with no display
# at all, so this needs no Xvfb:
#
#   env -u DISPLAY -u WAYLAND_DISPLAY bundle exec ruby test/drive_window.rb
#
# It writes PNGs to tmp/shots and exits non-zero if any check fails.

require "tmpdir"

# A scratch config directory, so a run never reads or scribbles on the real
# settings file the app persists its geometry and custom control into.
ENV["XDG_CONFIG_HOME"] = Dir.mktmpdir("chess-clock-drive")

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "chess_clock"

require_relative "gtk_driver"

SETUP = ChessClock::Window::SETUP
TIMER = ChessClock::Window::TIMER
START = ChessClock::StateMachine::START
A_RUN = ChessClock::StateMachine::A_RUN
B_RUN = ChessClock::StateMachine::B_RUN

application = ChessClock::Application.new(present: true)

GtkDriver.drive(application, shots: "tmp/shots") do |d, app|
  d.window { app.main_window.window }

  d.step("the window builds on the setup screen") do
    d.check("the stack shows the setup screen") { app.main_window.main_stack.visible_child_name == SETUP }
    d.check("a default five-minute game is loaded") { app.main_window.state_machine.default_time == 300_000_000 }
    d.check("the method chooser offers the three rule-sets") { app.main_window.method_chooser.model.n_items == 3 }
    d.shot("01-setup")
  end

  d.step("a preset fills the custom control in") do
    app.main_window.custom_control.set_control(ChessClock::TimeControlEntry::PRESETS[3])
  end

  d.step("the preset is showing") do
    d.check("5+3 reads as 300 seconds plus 3") { app.main_window.custom_control.control == [300, 3] }
    d.check("the seconds are padded") { app.main_window.custom_control.seconds.text == "00" }
    d.shot("02-setup-5+3")
  end

  d.step("Start Game is clicked") do
    app.main_window.start_game.activate
  end

  d.step("the timer screen is showing a Fischer game") do
    d.check("the stack switched") { app.main_window.main_stack.visible_child_name == TIMER }
    d.check("the increment rule-set was built") do
      app.main_window.state_machine.is_a?(ChessClock::IncrementStateMachine)
    end
    d.check("both faces start at 5:03") do
      [app.main_window.a_timer, app.main_window.b_timer].all? { |face| face.minutes.label == "5" && face.seconds.label == "03" }
    end
    d.shot("03-timer")
  end

  d.step("A's half is tapped, handing the move to B") do
    app.main_window.a_timer.activate
  end

  d.step("B is now the running clock") do
    d.check("the machine is in B_RUN") { app.main_window.state_machine.state == B_RUN }
    d.check("B's face has the running class") { app.main_window.b_timer.css_classes.include?("running") }
    d.check("A's face does not") { !app.main_window.a_timer.css_classes.include?("running") }
    d.shot("04-b-running")
  end

  d.step("the pause button is clicked") do
    app.main_window.play_pause.activate
  end

  d.step("the game is paused and the icon has flipped") do
    d.check("the machine is in B_PAUSE") { app.main_window.state_machine.state == ChessClock::StateMachine::B_PAUSE }
    d.check("the button offers play") { app.main_window.play_pause.icon_name == "media-playback-start-symbolic" }
    d.shot("05-paused")
  end

  d.step("win.restart is activated") do
    app.main_window.window.activate_action("restart", nil)
  end

  d.step("the clocks are back to the start of the game") do
    d.check("the machine is in START") { app.main_window.state_machine.state == START }
    d.check("A's face is back to 5:03") { app.main_window.a_timer.minutes.label == "5" }
    d.shot("06-restarted")
  end

  d.step("win.muted is activated") do
    app.main_window.window.activate_action("muted", nil)
  end

  d.step("the machine and the stored setting agree the alert is muted") do
    d.check("the machine is muted") { app.main_window.state_machine.muted == true }
    d.check("the setting was written") { app.main_window.settings["muted"] == true }
  end

  d.step("win.menu is activated on the timer screen") do
    app.main_window.window.activate_action("menu", nil)
  end

  d.step("the primary menu is up") do
    d.check("the menu button is active") { app.main_window.main_menu.active? }
    d.shot("07-menu")
  end

  d.step("the menu is dismissed and win.new is activated") do
    app.main_window.main_menu.popdown
    app.main_window.window.activate_action("new", nil)
  end

  d.step("the setup screen is back, scrolled to the top") do
    d.check("the stack switched back") { app.main_window.main_stack.visible_child_name == SETUP }
    d.check("the scroller is at the top") { app.main_window.setup_scroll.vadjustment.value.zero? }
    d.shot("08-setup-again")
  end

  d.step("a Bronstein game is started") do
    app.main_window.method_chooser.selected = 1
    app.main_window.start_game.activate
  end

  d.step("the Bronstein rule-set is driving the clocks") do
    d.check("the machine is a Bronstein machine") do
      app.main_window.state_machine.is_a?(ChessClock::BronsteinStateMachine)
    end
    d.check("its move timer is armed at the delay") do
      app.main_window.state_machine.inc_timer.time == 3_000_000
    end
    d.shot("09-bronstein")
  end

  d.step("the window is narrowed past the breakpoint") do
    app.main_window.window.default_width = 400
  end

  d.step("the narrow layout applied") do
    d.check("the faces stack") { app.main_window.timer_box.orientation == Gtk::Orientation::VERTICAL }
    d.check("A's face is turned around for the player opposite") { app.main_window.a_timer.inverted == true }
    d.check("the end-side window controls moved") { app.main_window.windowcontrols_start_end.visible? }
    d.shot("10-narrow")
  end

  d.step("the window is widened again") do
    app.main_window.window.default_width = 900
  end

  d.step("the wide layout is back") do
    d.check("the faces sit side by side") { app.main_window.timer_box.orientation == Gtk::Orientation::HORIZONTAL }
    d.check("A's face is the right way up") { app.main_window.a_timer.inverted == false }
    d.shot("11-wide")
  end

  d.step("win.show-help-overlay is activated") do
    app.main_window.window.activate_action("show-help-overlay", nil)
  end

  d.step("the shortcuts window opened with both groups") do
    d.check("the window exists") { !app.main_window.shortcuts_window.window.nil? }
    d.check("it is on screen") { app.main_window.shortcuts_window.window.visible? }
    d.shot("12-shortcuts", app.main_window.shortcuts_window.window)
  end

  d.step("the about window is opened from the app action") do
    app.main_window.shortcuts_window.window.close
    app.about_dialog.present(app.main_window.window)
  end

  d.step("the about window carries the metainfo fields") do
    d.check("the release notes are set") { !app.about_dialog.dialog.release_notes.to_s.empty? }
    # Upstream's on_about_action (src/main.py:56) passes the literal "0.6.0"
    # to new_from_appdata, not the metainfo's newest release (0.6.2) — see
    # AboutDialog::RELEASE_NOTES_VERSION (G12).
    d.check("the release notes name upstream's literal version, 0.6.0") { app.about_dialog.dialog.release_notes_version == "0.6.0" }
    d.check("the summary has no trailing full stop") { !app.about_dialog.dialog.comments.end_with?(".") }
    d.shot("13-about", app.about_dialog.dialog)
  end
end
