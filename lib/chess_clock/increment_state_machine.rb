# frozen_string_literal: true

require_relative "state_machine"

module ChessClock
  # IncrementStateMachine adds the Fischer increment rule.
  #
  # Ported from ChessClockIncrementStateMachine in src/statemachine.py. Each
  # player gets the increment added to their clock when they hand the move
  # over, and both clocks start the game with one increment already on them.
  # An expired clock is not topped up — Timer#increment without `force` leaves
  # a clock at zero alone — so the increment cannot revive a lost game.
  class IncrementStateMachine < StateMachine
    def to_start
      super
      @timer_a.increment(@inc, force: true)
      @timer_b.increment(@inc, force: true)
    end

    def to_a_run
      super
      # B just moved, so B is the one being paid.
      if @state == B_RUN
        @timer_b.increment(@inc)
      end
    end

    def to_b_run
      super
      if @state == A_RUN
        @timer_a.increment(@inc)
      end
    end
  end
end
