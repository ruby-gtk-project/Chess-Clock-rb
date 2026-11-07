# frozen_string_literal: true

require "chess_clock/alert_sound"

# Ported from the GSound.Context in src/statemachine.py, which plays
# {ATTR_EVENT_ID: "dialog-warning", ATTR_CANBERRA_VOLUME: "1"} on every
# `alerted` signal unless muted. See alert_sound.rb's header for the route
# through GObjectIntrospection::Loader and the fallbacks behind it (G5).
RSpec.describe ChessClock::AlertSound do
  subject(:sound) { described_class.new }

  it "starts unmuted by default" do
    expect(sound.muted).to eq(false)
  end

  it "takes muted as a constructor keyword" do
    expect(described_class.new(muted: true).muted).to eq(true)
  end

  it "is a plain accessor, not GObject-bindable" do
    sound.muted = true
    expect(sound.muted).to eq(true)
  end

  describe "#play" do
    it "does nothing and returns nil when muted" do
      expect(described_class.new(muted: true).play).to be_nil
    end

    it "takes some route rather than raising when unmuted" do
      expect { sound.play }.not_to raise_error
    end
  end

  describe "#gsound" do
    it "either resolves the typelib or returns nil, never raising" do
      expect { sound.gsound }.not_to raise_error
    end

    it "memoizes the result of loading the namespace" do
      expect(sound.gsound).to equal(sound.gsound)
    end
  end

  describe "#available?" do
    # The fork's flake carries the gsound package on GI_TYPELIB_PATH (closing
    # the typelib half of G5), so this is a real assertion: the namespace
    # resolves and GSound::Context#init succeeds in this dev shell.
    it "is true once the GSound typelib and its context are reachable" do
      expect(sound.available?).to eq(true)
    end

    # A new StateMachine, and so a new AlertSound, is built on every restart
    # and every new game (Window#link_state_machine). Loading GSound's
    # namespace into a fresh module per instance used to raise `NameError`
    # the second time, which the rescue in `gsound` swallowed into a quiet
    # `false` — so a real alert worked once per process and silently fell
    # back to the bell after that. `gsound` is memoized on the class now,
    # not on `self`, precisely so a second instance does not reload it.
    it "stays available across many instances, as a restarted game builds" do
      results = Array.new(5) { described_class.new.available? }
      expect(results).to eq([true, true, true, true, true])
    end
  end

  describe "#context" do
    it "never raises, even where GSound cannot be reached" do
      expect { sound.context }.not_to raise_error
    end

    it "memoizes the context" do
      expect(sound.context).to equal(sound.context)
    end
  end

  it "falls back without raising when GSound's own play call fails" do
    # Simulates a typelib that resolves and inits but whose sound server is
    # unreachable (GLib::Error, "Not available") — the exact shape this
    # sandbox's Xvfb display produces, with no PulseAudio/PipeWire/ALSA
    # device for libcanberra to open.
    allow(sound).to receive(:context).and_return(
      Class.new do
        def play_simple(*)
          raise GLib::Error, "Not available"
        end
      end.new,
    )
    expect { sound.play }.not_to raise_error
  end
end
