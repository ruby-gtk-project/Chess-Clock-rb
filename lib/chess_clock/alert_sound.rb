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
  # swallowed on a box where neither the typelib nor a sound server is
  # present.
  #
  # The fork's flake now carries the `gsound` package on GI_TYPELIB_PATH, so
  # `GObjectIntrospection::Loader.load("GSound", …)` resolves, `Context#init`
  # takes no arguments and succeeds, and `play_simple` does accept a plain
  # Ruby Hash for the GHashTable argument — all three were previously
  # unverified. What the dev shell's Xvfb sandbox still has no answer for is a
  # sound server: there is no PulseAudio, PipeWire or ALSA device here, so
  # `play_simple` itself raises `GLib::Error` ("Not available") once it
  # reaches libcanberra's backend. `emit_event` below now rescues that and
  # falls back exactly as it would for a missing typelib, so a real alert
  # degrades to the display bell on a box with no sound hardware instead of
  # crashing the window. The event has still not been heard by a human; it has
  # been proven to reach the point only real audio hardware can fail past.
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

    # The GSound namespace, loaded from its typelib the first time any
    # instance asks for it, or nil where no typelib is installed.
    #
    # Memoized on the class, not on `self`: a new StateMachine, and so a new
    # AlertSound, is built on every restart and every new game (window.rb's
    # #link_state_machine), and GObjectIntrospection::Loader raises
    # `NameError: private constant …::Context::INVOKERS referenced` the
    # second time a namespace already loaded in this process is loaded again
    # into a *different* target module — the loader's generated classes are
    # only safe to build once per process. Before this round, every AlertSound
    # past the process's first re-loaded the namespace into a fresh anonymous
    # module and hit exactly that, so `gsound` (and so `available?`) was true
    # on a game's first alert and silently false on every alert after a
    # restart, with the previous per-instance `@gsound ||=` never catching it
    # because each instance's cache missed. One shared namespace, built once,
    # closes that.
    # A missing typelib raises GObjectIntrospection::RepositoryError::TypelibNotFound,
    # which descends from LoadError and so from ScriptError, not StandardError:
    # a bare `rescue` would let it out and take the window down with it.
    def gsound = self.class.gsound

    class << self
      def gsound
        return @gsound if defined?(@gsound)

        @gsound = Module.new.tap { |namespace| GObjectIntrospection::Loader.load(NAMESPACE, namespace) }
      rescue StandardError, ScriptError
        @gsound = nil
      end
    end

    def context
      @context ||= gsound&.const_get(:Context)&.new&.tap { |ctx| initialise(ctx) }
    rescue StandardError, ScriptError
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
          if ctx && play_via_gsound(ctx)
            nil
          else
            spawn_player
          end
        end
      end

      # True on success. GSound's own context build/init failures are caught
      # in `context` above; this is the separate failure a present typelib and
      # a live context can still hit per call, such as no sound server being
      # reachable (`GLib::Error`, "Not available"), which must fall back the
      # same way a missing typelib does rather than take the window down.
      def play_via_gsound(ctx)
        ctx.play_simple(ATTRIBUTES)
        true
      rescue GLib::Error
        false
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
