# frozen_string_literal: true

require "chess_clock/timer"

require_relative "../support/fakes"

# Upstream has no test suite, so none of this is ported: it pins the rules
# src/timer.py implements, read off that file, so a port edit that breaks one
# of them fails here instead of shipping.
RSpec.describe ChessClock::Timer do
  subject(:timer) { described_class.new(machine) }

  let(:clock) { Fakes::Clock.new }
  let(:window) { Fakes::Window.new }
  let(:machine) { Fakes::Machine.new(default_time: default_time, window: window) }
  let(:default_time) { 300_000_000 }

  before do
    allow(timer).to receive(:monotonic_time) { clock.now }
  end

  # One tick of the frame clock, after letting `micros` of monotonic time pass.
  def tick(micros)
    clock.advance(micros)
    timer.on_tick
  end

  def start
    timer.running = true
  end

  describe "#reset" do
    it "takes the time from the machine's default and stops the clock" do
      timer.time = 1
      timer.reset
      expect([timer.time, timer.running]).to eq([default_time, false])
    end

    it "emits changed with the restored time" do
      times = []
      timer.connect(:changed) { |_timer, time| times << time }
      timer.reset
      expect(times).to eq([default_time])
    end
  end

  describe "the countdown" do
    it "charges elapsed monotonic time, not a fixed amount per frame" do
      start
      tick(250_000)
      tick(16_000)
      expect(timer.time).to eq(default_time - 266_000)
    end

    it "never goes below zero" do
      start
      tick(default_time * 2)
      expect(timer.time).to eq(0)
    end

    it "stops ticking, and removes its callback, once running is false" do
      start
      timer.running = false
      expect(timer.on_tick).to be(false)
    end

    it "does not charge the time that passed while it was stopped" do
      start
      tick(1_000_000)
      timer.running = false
      clock.advance(60_000_000)
      timer.running = true
      tick(1_000_000)
      expect(timer.time).to eq(default_time - 2_000_000)
    end
  end

  describe "the expired signal" do
    it "fires exactly once, on the crossing tick" do
      expirations = 0
      timer.connect(:expired) { expirations += 1 }
      start
      tick(default_time)
      tick(1_000_000)
      tick(1_000_000)
      expect(expirations).to eq(1)
    end

    it "does not fire on a tick that leaves time on the clock" do
      expirations = 0
      timer.connect(:expired) { expirations += 1 }
      start
      tick(default_time - 1)
      expect([timer.time, expirations]).to eq([1, 0])
    end
  end

  describe "the alerted signal" do
    it "fires at a tenth of the default time for a game long enough for it" do
      alerts = []
      timer.connect(:alerted) { alerts << timer.time }
      start
      tick(default_time - 30_000_001)
      expect(alerts).to be_empty
      tick(1)
      expect(alerts).to eq([30_000_000])
    end

    context "with a one-minute game, whose tenth is under the floor" do
      let(:default_time) { 60_000_000 }

      # max(int(default_time * 0.1), MINIMUM_ALERT_TIME) in src/timer.py:72: the
      # floor raises the threshold, so a short game alerts with ten seconds left
      # rather than with its own tenth, six.
      it "alerts with ten seconds left rather than with six" do
        alerts = []
        timer.connect(:alerted) { alerts << timer.time }
        start
        tick(default_time - 10_000_001)
        expect(alerts).to be_empty
        tick(1)
        expect(alerts).to eq([10_000_000])
      end
    end

    it "fires once per game, however many ticks follow" do
      alerts = 0
      timer.connect(:alerted) { alerts += 1 }
      start
      tick(default_time - 1_000_000)
      tick(100_000)
      tick(100_000)
      expect(alerts).to eq(1)
    end

    it "arms again after a reset" do
      alerts = 0
      timer.connect(:alerted) { alerts += 1 }
      start
      tick(default_time - 1_000_000)
      timer.reset
      start
      tick(default_time - 1_000_000)
      expect(alerts).to eq(2)
    end
  end

  describe "#increment" do
    it "adds to a clock with time left and announces the new time" do
      times = []
      timer.connect(:changed) { |_timer, time| times << time }
      timer.increment(5_000_000)
      expect([timer.time, times]).to eq([default_time + 5_000_000, [default_time + 5_000_000]])
    end

    it "leaves an expired clock expired, so an increment cannot revive it" do
      start
      tick(default_time)
      timer.increment(5_000_000)
      expect(timer.time).to eq(0)
    end

    it "tops an expired clock up when forced, which is how a new game starts" do
      start
      tick(default_time)
      timer.increment(5_000_000, force: true)
      expect(timer.time).to eq(5_000_000)
    end
  end

  describe "the frame-clock callback" do
    it "is installed on the machine's window when the clock starts running" do
      start
      expect(window.tick_callbacks.size).to eq(1)
    end

    it "is not installed a second time while it is already running" do
      start
      timer.running = true
      expect(window.tick_callbacks.size).to eq(1)
    end
  end
end
