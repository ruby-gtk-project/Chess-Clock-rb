# frozen_string_literal: true

require "gtk4"
require_relative "signals"
require_relative "timer"
require_relative "alert_sound"

module ChessClock
  # StateMachine is the game's state machine: whose clock runs, which half of
  # the window is white, and whether the session may go idle.
  #
  # Ported from src/statemachine.py (MachineState and ChessClockStateMachine).
  # The five states and the five signals are upstream's:
  #
  #   a_active(active, paused)  the A button's sensitivity, and whether it is
  #                             the running clock
  #   b_active(active, paused)  the same for B
  #   pause(active, paused)     the play/pause button's sensitivity and icon
  #   awbb                      A is white, B is black
  #   abbw                      A is black, B is white
  #
  # State is assigned, not transitioned: `machine.state = A_RUN` runs the
  # to_a_run hook and only then records the new state, which is why every hook
  # can still read the state it is leaving. The subclasses in
  # increment_state_machine.rb, bronstein_state_machine.rb and
  # delay_state_machine.rb hang their time-control rules off those hooks.
  class StateMachine
    include Signals

    START = :start
    A_RUN = :a_run
    B_RUN = :b_run
    A_PAUSE = :a_pause
    B_PAUSE = :b_pause

    attr_reader :window, :app, :timer_a, :timer_b, :state, :default_time, :inc

    # time and inc arrive in seconds, as the time control entry reports them.
    def initialize(window, time, inc)
      @window = window
      @app = window.application
      @idle_cookie = 0
      set_time_control(time, inc)

      @timer_a = Timer.new(self)
      @timer_b = Timer.new(self)

      @handler_ids = []
      @handler_ids_ta = []
      @handler_ids_tb = []
      @button_handler_ids = []

      @alert_sound = AlertSound.new
      self.state = START
    end

    # Microseconds from here on: the timers count in them.
    def set_time_control(time, inc)
      @default_time = (time * 1_000_000).to_i
      @inc = (inc * 1_000_000).to_i
    end

    def muted = @alert_sound.muted

    def muted=(muted)
      @alert_sound.muted = muted
    end

    def timer_alerted(*_args)
      @alert_sound.play
    end

    def state=(state)
      case state
      when START then to_start
      when A_RUN then to_a_run
      when B_RUN then to_b_run
      when A_PAUSE then to_a_pause
      when B_PAUSE then to_b_pause
      end
      @state = state
    end

    # --- Button wiring -------------------------------------------------------

    # Every id is kept so disconnect_all can undo the whole wiring when the
    # window swaps one machine for another; a leftover handler would otherwise
    # drive a dead machine's timers from a live button.
    def add_a_button(button)
      @handler_ids << connect(:a_active, button.method(:on_active))
      @handler_ids << connect(:awbb, button.method(:on_white))
      @handler_ids << connect(:abbw, button.method(:on_black))
      @handler_ids_ta << @timer_a.connect(:changed, button.method(:on_changed))
      @handler_ids_ta << @timer_a.connect(:alerted, method(:timer_alerted))
      @button_handler_ids << [button, button.signal_connect("clicked") { on_a_clicked }]
    end

    def add_b_button(button)
      @handler_ids << connect(:b_active, button.method(:on_active))
      @handler_ids << connect(:awbb, button.method(:on_black))
      @handler_ids << connect(:abbw, button.method(:on_white))
      @handler_ids_tb << @timer_b.connect(:changed, button.method(:on_changed))
      @handler_ids_tb << @timer_b.connect(:alerted, method(:timer_alerted))
      @button_handler_ids << [button, button.signal_connect("clicked") { on_b_clicked }]
    end

    def disconnect_all
      @handler_ids.each { |id| disconnect(id) }
      @handler_ids_ta.each { |id| @timer_a.disconnect(id) }
      @handler_ids_tb.each { |id| @timer_b.disconnect(id) }
      @button_handler_ids.each { |(button, id)| button.signal_handler_disconnect(id) }
      @handler_ids = []
      @handler_ids_ta = []
      @handler_ids_tb = []
      @button_handler_ids = []
    end

    # --- Clicks --------------------------------------------------------------

    # Tapping your own half hands the move over, so A's click starts B.
    def on_a_clicked(*_args)
      self.state = B_RUN
    end

    def on_b_clicked(*_args)
      self.state = A_RUN
    end

    def on_pause_clicked(*_args)
      case @state
      when A_RUN then self.state = A_PAUSE
      when B_RUN then self.state = B_PAUSE
      when A_PAUSE then self.state = A_RUN
      when B_PAUSE then self.state = B_RUN
      end
    end

    # --- State hooks ---------------------------------------------------------

    def to_start
      @timer_a.reset
      @timer_b.reset
      emit(:a_active, true, false)
      emit(:b_active, true, false)
      uninhibit_idle
      # Nothing to pause while both clocks are stopped.
      emit(:pause, false, false)
    end

    def to_a_run
      if @state == START
        emit(:awbb)
      end
      @timer_b.running = false
      @timer_a.running = true
      emit(:a_active, true, true)
      emit(:b_active, false, false)
      # Coming from B_RUN the session is already inhibited.
      if @state != B_RUN
        inhibit_idle
      end
      emit(:pause, true, false)
    end

    def to_b_run
      if @state == START
        emit(:abbw)
      end
      @timer_a.running = false
      @timer_b.running = true
      emit(:a_active, false, false)
      emit(:b_active, true, true)
      if @state != A_RUN
        inhibit_idle
      end
      emit(:pause, true, false)
    end

    def to_a_pause
      @timer_a.running = false
      emit(:a_active, false, true)
      uninhibit_idle
      # Active, showing a play icon.
      emit(:pause, true, true)
    end

    def to_b_pause
      @timer_b.running = false
      emit(:b_active, false, true)
      uninhibit_idle
      emit(:pause, true, true)
    end

    private

    # A running game clock is watched, not interacted with, so the session must
    # not blank the screen under it.
      def inhibit_idle
        @idle_cookie = @app&.inhibit(@window, Gtk::ApplicationInhibitFlags::IDLE, "Game clock running").to_i
      end

      def uninhibit_idle
        if @idle_cookie.positive?
          @app&.uninhibit(@idle_cookie)
        end
        @idle_cookie = 0
      end
  end
end
