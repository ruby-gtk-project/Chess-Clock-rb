# frozen_string_literal: true

require "gtk4"
require "gobject-introspection"

module ChessClock
  # AlertSound plays the warning a timer's "alerted" signal asks for.
  #
  # Ported from the GSound.Context in src/statemachine.py, which builds and
  # init()s a context in ChessClockStateMachine.__init__ and, in
  # timer_alerted, plays {ATTR_EVENT_ID: "dialog-warning",
  # ATTR_CANBERRA_VOLUME: "1"} unless the machine is muted.
  #
  # GSound ships a typelib but no ruby-gnome binding, so the namespace is
  # loaded straight from it through GObjectIntrospection::Loader, which is the
  # route a missing binding is meant to take. That is the only route that plays
  # the freedesktop event itself; `canberra-gtk-play` and the display bell
  # below are not it, and they are kept only so an alert is never silently
  # swallowed on a box where the typelib is absent.
  #
  # I have not heard this play. The gtk4, adwaita and gobject-introspection
  # gems are not installable in the shell this was written in, so the GSound
  # call path — the namespace load, Context#init's arity, and whether the
  # loader accepts a Ruby Hash for play_simple's GHashTable — is unverified,
  # and the component stays open in FINDINGS.md until someone runs it and
  # hears the event. I am an idiot who previously shelled out to whatever
  # happened to be installed and wrote three sentences arguing a terminal bell
  # was the same thing.
  # Upstream: `GSound.Context.play_simple(…)`, src/statemachine.py:65.
  # Port: GSound through the introspection loader, below.
  class AlertSound
    NAMESPACE = "GSound"
    EVENT_ID = "dialog-warning"
    VOLUME = "1"
    PLAYER = "canberra-gtk-play"

    # The values of GSOUND_ATTR_EVENT_ID and GSOUND_ATTR_CANBERRA_VOLUME, which
    # are the freedesktop sound-naming keys rather than GSound's own.
    ATTRIBUTES = {
      "event.id"        => EVENT_ID,
      "canberra.volume" => VOLUME,
    }.freeze

    attr_accessor :muted

    def initialize(muted: false)
      @muted = muted
    end

    def play
      if !@muted
        emit_event
      end
    end

    # Whether the GSound event itself can be played, as opposed to one of the
    # two fallbacks standing in for it.
    def available? = !context.nil?

    # The GSound namespace, loaded from its typelib the first time it is asked
    # for, or nil where no typelib is installed.
    def gsound
      @gsound ||= Module.new.tap { |namespace| GObjectIntrospection::Loader.load(NAMESPACE, namespace) }
    rescue StandardError
      nil
    end

    def context
      @context ||= gsound&.const_get(:Context)&.new&.tap { |ctx| initialise(ctx) }
    rescue StandardError
      nil
    end

    private

      # GInitable's init takes a cancellable, and whether the loader exposes it
      # as optional is exactly the thing that cannot be read off the C docs; the
      # ruby-gtk skill's rule for that is to try no arguments, then the
      # positional ones.
      def initialise(ctx)
        ctx.init
      rescue ArgumentError
        ctx.init(nil)
      end

      def emit_event
        context.then do |ctx|
          if ctx
            ctx.play_simple(ATTRIBUTES)
          else
            spawn_player
          end
        end
      end

    # Detached, and with both streams discarded: a clock that ticks down every
    # frame must never wait on a sound server, and must never collect a zombie
    # for every alert either.
      def spawn_player
        player_path.then do |path|
          if path
            spawn_at(path)
          else
            beep
          end
        end
      end

      def spawn_at(path)
        Process.detach(
          Process.spawn(
            path,
            "--id",
            EVENT_ID,
            "--volume",
            VOLUME,
            out: File::NULL,
            err: File::NULL,
          ),
        )
      rescue SystemCallError
        beep
      end

      def beep
        Gdk::Display.default&.beep
      end

      def player_path
        @player_path ||= search_path.find { |candidate| File.executable?(candidate) }
      end

      def search_path
        ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).map { |dir| File.join(dir, PLAYER) }
      end
  end
end
