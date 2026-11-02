# frozen_string_literal: true

require_relative "fakes"

# Drives a state machine's timers off a clock the example controls.
#
# Every ChessClock::Timer reads elapsed monotonic microseconds for itself, so a
# machine's two player clocks and its delay or move timer each have to be
# pointed at the same fake clock, and each has to be ticked. Including this
# module gives an example `clock`, `machine_timers`, and a `tick` that does
# one frame for all of them.
module MachineClock
  def self.included(base)
    base.let(:clock) { Fakes::Clock.new }
    base.let(:app) { Fakes::Application.new }
    base.let(:window) { Fakes::Window.new(application: app) }
    base.before { machine_timers.each { |timer| allow(timer).to receive(:monotonic_time) { clock.now } } }
  end

  # The player clocks, plus whichever third timer the rule-set adds.
  def machine_timers
    [machine.timer_a, machine.timer_b, extra_timer].compact
  end

  def extra_timer
    [:inc_timer, :delay_timer]
      .select { |name| machine.respond_to?(name) }
      .map { |name| machine.send(name) }
      .first
  end

  # One turn of the frame clock, after letting `micros` of monotonic time pass.
  def tick(micros)
    clock.advance(micros)
    machine_timers.each(&:on_tick)
  end
end
