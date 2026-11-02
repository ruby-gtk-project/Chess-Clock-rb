# frozen_string_literal: true

require_relative "state_machine"
require_relative "timer"

module ChessClock
  # BronsteinStateMachine adds the Bronstein delay rule.
  #
  # Ported from ChessClockBronsteinStateMachine in src/statemachine.py.
  # Bronstein delay refunds the time a move actually took, up to the delay: a
  # move spending less than the delay costs nothing, a move spending more costs
  # only the excess. A third timer measures the move. It starts at the delay
  # and runs down while the player thinks, so what is left of it is the unused
  # delay, and `inc - inc_timer.time` is what the move cost — capped at the
  # delay, since the move timer can only run out once.
  #
  # The move timer is built before `super` because StateMachine's constructor
  # already assigns a state, and that assignment runs to_start here, which
  # needs the timer; the same reason upstream sets default_time before calling
  # up. A Timer reads its machine's default_time when it is created, and zero
  # is the right starting point for a timer whose time to_start sets by hand.
  class BronsteinStateMachine < StateMachine
    attr_reader :inc_timer

    def initialize(window, time, inc)
      @default_time = 0
      @inc_timer = Timer.new(self)
      super
    end

    def to_start
      super
      @timer_a.increment(@inc, force: true)
      @timer_b.increment(@inc, force: true)
      @inc_timer.reset
      @inc_timer.time = @inc
      @inc_timer.running = false
    end

    def to_a_run
      @inc_timer.running = false
      super
      if @state == B_RUN
        @timer_b.increment([@inc - @inc_timer.time, @inc].min)
        @inc_timer.time = @inc
      end
      @inc_timer.running = true
    end

    def to_b_run
      @inc_timer.running = false
      super
      if @state == A_RUN
        @timer_a.increment([@inc - @inc_timer.time, @inc].min)
        @inc_timer.time = @inc
      end
      @inc_timer.running = true
    end

    def to_a_pause
      @inc_timer.running = false
      super
    end

    def to_b_pause
      @inc_timer.running = false
      super
    end
  end
end
