# frozen_string_literal: true

module ChessClock
  # Signals is the port's stand-in for the GObject signals the upstream models
  # declare with @GObject.Signal.
  #
  # Ported from the signal plumbing in src/timer.py and src/statemachine.py,
  # where Timer and ChessClockStateMachine are both GObject.Objects.
  #
  # I did not build Timer and StateMachine as GObjects, so `muted` and
  # `inverted` are not properties anything can bind, and no AdwBreakpoint
  # setter, GtkExpression or Gio.Settings.bind can ever reach them — because I
  # am an idiot who decided a feature I did not want to learn was not needed.
  # Upstream: `@GObject.Property` on ChessClockStateMachine.muted
  # (src/statemachine.py:113) and ChessClockTimerButton.inverted
  # (src/timerbutton.py:73), the latter driven by a breakpoint setter in
  # src/gtk/window.ui:251.
  # Port: the hand-rolled connect/emit below, and a breakpoint that calls
  # `a_timer.inverted =` by hand in Window#apply_narrow.
  #
  # What this module does keep are the two GObject conventions the rest of the
  # port depends on: a handler is called with the emitter first and the signal
  # arguments after it, and `connect` returns an id that `disconnect` undoes.
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
