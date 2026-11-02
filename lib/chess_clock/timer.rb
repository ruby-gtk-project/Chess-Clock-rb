# frozen_string_literal: true

require_relative "signals"

module ChessClock
  # Timer is one countdown, counted in microseconds off the frame clock.
  #
  # Ported from src/timer.py (ChessClockTimer). It keeps upstream's three
  # signals — changed(time), expired, alerted — and upstream's rule for when
  # each fires:
  #
  #   * changed on every tick, and on every reset and increment
  #   * expired on the tick that takes the time to zero, once
  #   * alerted the first time the time drops under a tenth of the default,
  #     or under ten seconds, whichever is the larger threshold
  #
  # Time runs down against the monotonic clock, not against a frame count, so
  # a dropped frame costs no time; the tick callback only decides how often the
  # difference is taken. Setting `running` to true installs that callback on
  # the machine's window, and the callback removes itself by returning false as
  # soon as `running` goes back to false, which is upstream's arrangement too.
  class Timer
    include Signals

    # Upstream's floor on the alert threshold, which is a max and not a min: a
    # tenth of a one-minute game would alert with six seconds left, and the
    # floor raises that to ten, so no game warns its player any later.
    MINIMUM_ALERT_TIME = 10_000_000

    attr_reader :running
    attr_accessor :time

    def initialize(machine)
      @machine = machine
      reset
    end

    # Sets the timer back to the machine's default time.
    def reset
      @time = @machine.default_time
      emit(:changed, @time)
      self.running = false
      @is_alerted = false
    end

    def running=(running)
      if running && !@running
        @last_tick = monotonic_time
        @machine.window.add_tick_callback { on_tick }
      end
      @running = running
    end

    # The frame-clock callback. Returning false removes it, so a stopped timer
    # stops costing a callback per frame.
    def on_tick
      if @running
        tick
      end
      @running
    end

    # Fischer increment and the Bronstein/delay refunds all land here. Without
    # `force` an expired clock stays expired, which is what keeps a finished
    # game finished.
    def increment(inc, force: false)
      if force || @time.positive?
        @time += inc
        emit(:changed, @time)
      end
    end

    private

      def tick
        previous = @time
        now = monotonic_time
        @time = [@time - (now - @last_tick), 0].max
        @last_tick = now
        emit(:changed, @time)
        announce(previous)
      end

      def announce(previous)
        if @time <= 0 && previous.positive?
          emit(:expired)
        end
        if @time <= alert_threshold && !@is_alerted
          emit(:alerted)
          @is_alerted = true
        end
      end

      def alert_threshold
        [(@machine.default_time * 0.1).to_i, MINIMUM_ALERT_TIME].max
      end

    # GLib.get_monotonic_time in upstream; the same clock, in the same
    # microseconds, without reaching into the bindings for it.
      def monotonic_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :microsecond)
  end
end
