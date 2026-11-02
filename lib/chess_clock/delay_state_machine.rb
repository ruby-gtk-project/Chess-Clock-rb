# frozen_string_literal: true

require_relative "state_machine"
require_relative "timer"

module ChessClock
  # DelayStateMachine adds the simple (US) delay rule.
  #
  # Ported from ChessClockDelayStateMachine in src/statemachine.py. Simple
  # delay holds the moving player's clock still for the length of the delay and
  # only then starts counting: the delay is not time you can save, it is time
  # before the clock moves at all. A delay timer counts the standstill down and
  # starts the player's clock from its "expired" signal.
  #
  # As in bronstein_state_machine.rb, the delay timer is built before `super`
  # because the constructor's first state assignment already needs it.
  class DelayStateMachine < StateMachine
    attr_reader :delay_timer

    def initialize(window, time, inc)
      @default_time = 0
      @delay_timer = Timer.new(self)
      @delay_timer.connect(:expired, method(:timer_expired))
      super
    end

    # The standstill is over; whoever is on the move starts counting.
    def timer_expired(*_args)
      if @state == A_RUN
        @timer_a.running = true
      end
      if @state == B_RUN
        @timer_b.running = true
      end
    end

    def to_start
      super
      @delay_timer.reset
      @delay_timer.time = @inc
      @delay_timer.running = false
    end

    def to_a_run
      @delay_timer.running = false
      super
      # Resuming from a pause mid-delay: the rest of the delay still applies.
      if @delay_timer.time.positive?
        @timer_a.running = false
      end
      # A fresh move restarts the delay from the top.
      if @state == B_RUN
        @delay_timer.time = @inc
        @timer_a.running = false
      end
      @delay_timer.running = true
    end

    def to_b_run
      @delay_timer.running = false
      super
      if @delay_timer.time.positive?
        @timer_b.running = false
      end
      if @state == A_RUN
        @delay_timer.time = @inc
        @timer_b.running = false
      end
      @delay_timer.running = true
    end

    def to_a_pause
      @delay_timer.running = false
      super
    end

    def to_b_pause
      @delay_timer.running = false
      super
    end
  end
end
