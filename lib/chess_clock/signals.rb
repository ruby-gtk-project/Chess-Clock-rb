# frozen_string_literal: true

module ChessClock
  # Signals is the port's stand-in for the GObject signals the upstream models
  # declare with @GObject.Signal.
  #
  # Ported from the signal plumbing in src/timer.py and src/statemachine.py.
  # Both are GObject.Objects for one reason: `connect`, `emit`, and the integer
  # handler ids the window hands back to ChessClockStateMachine.disconnect_all
  # when a game ends. Nothing outside the application ever connects to them, so
  # registering new GObject types from Ruby would buy nothing and cost the
  # type_register/signal-definition dance. The models stay plain Ruby objects
  # and take connect/emit from here instead, keeping GObject's two conventions
  # that the rest of the port depends on: a handler is called with the emitter
  # first and the signal arguments after it, and `connect` returns an id that
  # `disconnect` undoes.
  module Signals
    def connect(name, callable = nil, &block)
      next_handler_id.tap do |id|
        signal_handlers[id] = [name.to_sym, callable || block]
      end
    end

    def disconnect(id)
      signal_handlers.delete(id)
    end

    def emit(name, *args)
      signal_handlers.values.each do |(handler_name, handler)|
        if handler_name == name.to_sym
          handler.call(self, *args)
        end
      end
    end

    private

      def signal_handlers = @signal_handlers ||= {}

      def next_handler_id
        @last_handler_id = (@last_handler_id || 0) + 1
      end
  end
end
