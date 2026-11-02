# frozen_string_literal: true

# Fakes standing in for the GTK objects the models reach for.
#
# ChessClock::Timer asks its machine for a window and installs a frame-clock
# callback on it; ChessClock::StateMachine asks the window for its application
# and inhibits the session on it. None of that needs a real widget, so these
# record what was asked instead, and the specs step the clock by hand.
module Fakes
  # Records every tick callback installed on it, so a spec can run one tick at
  # a time instead of waiting for a frame.
  class Window
    attr_reader :tick_callbacks, :application

    def initialize(application: nil)
      @application = application
      @tick_callbacks = []
    end

    def add_tick_callback(&block)
      @tick_callbacks << block
      @tick_callbacks.size
    end
  end

  # The subset of Gtk::Application the state machine's idle inhibit uses.
  class Application
    attr_reader :inhibited, :uninhibited

    def initialize
      @inhibited = []
      @uninhibited = []
      @next_cookie = 0
    end

    def inhibit(window, flags, reason)
      @inhibited << [window, flags, reason]
      @next_cookie += 1
    end

    def uninhibit(cookie)
      @uninhibited << cookie
    end
  end

  # Enough of ChessClock::StateMachine for a Timer: the two values a Timer
  # reads, and the window it installs its callback on.
  class Machine
    attr_reader :window
    attr_accessor :default_time, :inc

    def initialize(default_time:, inc: 0, window: Window.new)
      @default_time = default_time
      @inc = inc
      @window = window
    end
  end

  # Enough of a TimerButton for StateMachine#add_a_button: the handlers it
  # connects to the machine's and the timer's signals, and a GTK-style clicked
  # connection that can be disconnected by id.
  class Button
    attr_reader :actives, :whites, :blacks, :changes, :clicked_handlers, :disconnected

    def initialize
      @actives = []
      @whites = []
      @blacks = []
      @changes = []
      @clicked_handlers = {}
      @disconnected = []
      @next_handler_id = 0
    end

    def on_active(_machine, active, current) = @actives << [active, current]
    def on_white(*_args) = @whites << true
    def on_black(*_args) = @blacks << true
    def on_changed(_timer, time) = @changes << time

    def signal_connect(_name, &block)
      @next_handler_id += 1
      @clicked_handlers[@next_handler_id] = block
      @next_handler_id
    end

    def signal_handler_disconnect(id)
      @disconnected << id
      @clicked_handlers.delete(id)
    end

    def click
      @clicked_handlers.each_value(&:call)
    end
  end

  # Steps a Timer's monotonic clock by hand. Timer measures elapsed monotonic
  # microseconds rather than counting frames, so a spec that controls the clock
  # controls the countdown exactly.
  class Clock
    attr_reader :now

    def initialize(now: 1_000_000_000)
      @now = now
    end

    def advance(micros)
      @now += micros
    end
  end
end
