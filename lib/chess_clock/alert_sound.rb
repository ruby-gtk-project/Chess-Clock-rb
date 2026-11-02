# frozen_string_literal: true

require "gtk4"

module ChessClock
  # AlertSound plays the warning a timer's "alerted" signal asks for.
  #
  # Ported from the GSound.Context in src/statemachine.py, which initialises a
  # context in ChessClockStateMachine.__init__ and, in timer_alerted, plays
  # {EVENT_ID: "dialog-warning", CANBERRA_VOLUME: "1"} unless the machine is
  # muted.
  #
  # GSound has no Ruby bindings. It is a thin wrapper around libcanberra, so
  # the same freedesktop sound event is played through libcanberra's own player
  # instead; where that is not installed, the display's system bell stands in,
  # which is the same "something audible happened" the event is there for.
  # Muting is held here rather than checked by the caller, so a muted clock
  # cannot make a sound by a caller forgetting to ask.
  class AlertSound
    EVENT_ID = "dialog-warning"
    VOLUME = "1"
    PLAYER = "canberra-gtk-play"

    attr_accessor :muted

    def initialize(muted: false)
      @muted = muted
    end

    def play
      if !@muted
        emit_event
      end
    end

    # Whether the freedesktop sound event itself can be played, as opposed to
    # the bell standing in for it.
    def available? = !player_path.nil?

    private

      def emit_event
        player_path.then do |path|
          if path
            spawn_player(path)
          else
            beep
          end
        end
      end

    # Detached, and with both streams discarded: a clock that ticks down every
    # frame must never wait on a sound server, and must never collect a zombie
    # for every alert either.
      def spawn_player(path)
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
