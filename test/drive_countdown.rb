#!/usr/bin/env ruby
# frozen_string_literal: true

# Drives a real game down to zero.
#
# drive_window.rb proves the window builds and every screen, action and
# breakpoint works, but it never lets a clock run long enough to count: every
# check it makes would pass against a frozen timer. This one starts a
# two-second game and watches the frame clock take it apart — the digits fall,
# the alert fires, the clock expires and the face turns red — which is the only
# way the tick callback, the alert threshold and the expired styling get
# exercised at all.
#
#   nix develop --command xvfb-run -a ruby test/drive_countdown.rb
#
# It writes PNGs to tmp/shots and exits non-zero if any check fails.

require "tmpdir"

# A scratch config directory, so a run never reads or scribbles on the real
# settings the app persists its geometry and custom control into. The file
# store is forced for the same reason: a run must not write into the session's
# dconf.
ENV["XDG_CONFIG_HOME"] = Dir.mktmpdir("chess-clock-countdown")

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "chess_clock"

require_relative "gtk_driver"

# Two seconds a side, no increment: short enough that the whole game fits in a
# handful of the driver's half-second steps.
GAME = { label: "0+0", minutes: 0, seconds: 2, increment: 0 }.freeze

A_RUN = ChessClock::StateMachine::A_RUN
B_RUN = ChessClock::StateMachine::B_RUN

application = ChessClock::Application.new(
  settings: ChessClock::Settings.new(path: File.join(ENV.fetch("XDG_CONFIG_HOME"), "settings.json")),
  present:  true,
)

GtkDriver.drive(application, shots: "tmp/shots") do |d, app|
  d.window { app.main_window.window }

  # Everything the steps below read off the running machine, recorded as the
  # machine emits it: a signal that fired and was gone before the next step
  # looked cannot be asked about afterwards.
  seen = { alerted: 0, expired: 0, changed: 0 }

  d.step("a two-second game is set up and started") do
    app.main_window.custom_control.set_control(GAME)
    app.main_window.method_chooser.selected = 0
    app.main_window.start_game.activate
  end

  # `Gtk::Button#activate` does not emit "clicked" inline: GtkButton's activate
  # handler runs the pressed animation first and emits on a timeout, so the
  # machine the click builds does not exist until the loop has had a turn.
  # Probing it in the same step would wire up the machine the window was built
  # with, which is then thrown away.
  d.step("the clocks are armed but not yet counting") do
    app.main_window.state_machine.then do |machine|
      machine.timer_a.connect(:alerted) { seen[:alerted] += 1 }
      machine.timer_a.connect(:expired) { seen[:expired] += 1 }
      machine.timer_a.connect(:changed) { seen[:changed] += 1 }
    end

    d.check("A starts at two seconds") { app.main_window.state_machine.timer_a.time == 2_000_000 }
    d.check("A's face reads 0:02") do
      app.main_window.a_timer.minutes.label == "0" && app.main_window.a_timer.seconds.label == "02"
    end
    d.check("nothing has ticked yet") { seen[:changed].zero? }
    d.shot("20-countdown-armed")
  end

  # Tapping B hands the move to A, which is the only way to start A's clock.
  d.step("B's half is tapped, starting A's clock") do
    app.main_window.b_timer.activate
  end

  d.step("A's clock is running and the alert has already fired") do
    d.check("the machine is in A_RUN") { app.main_window.state_machine.state == A_RUN }
    d.check("the frame clock is ticking A down") { seen[:changed].positive? }
    d.check("A has lost time") { app.main_window.state_machine.timer_a.time < 2_000_000 }
    # The threshold is max(10% of the default, ten seconds), and a two-second
    # game is under ten seconds from its first tick.
    d.check("the alert fired once") { seen[:alerted] == 1 }
    d.check("A is not expired yet") { !app.main_window.a_timer.css_classes.include?("expired") }
    d.shot("21-countdown-running")
  end

  # Three half-second steps, so the two-second clock is comfortably past zero
  # whatever the frame rate the offscreen renderer settles on.
  3.times do |i|
    d.step("waiting for A to run out (#{i + 1}/3)") { nil }
  end

  d.step("A has run out") do
    d.check("A is at zero") { app.main_window.state_machine.timer_a.time.zero? }
    d.check("A's face reads 0:00") do
      app.main_window.a_timer.minutes.label == "0" && app.main_window.a_timer.seconds.label == "00"
    end
    d.check("the expired styling is on") { app.main_window.a_timer.css_classes.include?("expired") }
    d.check("expired fired exactly once") { seen[:expired] == 1 }
    d.check("the alert did not fire again") { seen[:alerted] == 1 }
    d.check("B never lost any time") { app.main_window.state_machine.timer_b.time == 2_000_000 }
    d.shot("22-countdown-expired")
  end

  # An expired clock stays expired: Timer#increment without force is how
  # upstream keeps a finished game finished.
  d.step("A's half is tapped, handing the move to B") do
    app.main_window.a_timer.activate
  end

  d.step("the move changed hands and A stayed at zero") do
    d.check("the machine is in B_RUN") { app.main_window.state_machine.state == B_RUN }
    d.check("A is still at zero") { app.main_window.state_machine.timer_a.time.zero? }
    d.check("A's face is still expired") { app.main_window.a_timer.css_classes.include?("expired") }
    d.check("B is the running clock now") { app.main_window.b_timer.css_classes.include?("running") }
    d.shot("23-countdown-handed-over")
  end

  d.step("the game is restarted") do
    app.main_window.window.activate_action("restart", nil)
  end

  d.step("both clocks are back at two seconds and unexpired") do
    d.check("A is back at two seconds") { app.main_window.state_machine.timer_a.time == 2_000_000 }
    d.check("A's face is no longer expired") { !app.main_window.a_timer.css_classes.include?("expired") }
    d.check("A's face reads 0:02 again") { app.main_window.a_timer.seconds.label == "02" }
    d.shot("24-countdown-restarted")
  end
end
