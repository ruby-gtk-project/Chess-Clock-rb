# frozen_string_literal: true

require "chess_clock/delay_state_machine"

require_relative "../support/machine_clock"

# Simple (US) delay, from ChessClockDelayStateMachine in src/statemachine.py:
# the moving player's clock stands still for the length of the delay and only
# then counts down. The delay is not time a player can bank — unlike Bronstein,
# nothing is ever added to a clock here.
#
# The two branches in to_a_run do different things and both stop the clock:
# `delay_timer.time.positive?` is a pause resumed mid-delay, and
# `@state == B_RUN` is a fresh move. Getting them the wrong way round gives a
# player a full delay for every pause.
RSpec.describe ChessClock::DelayStateMachine do
  include MachineClock

  subject(:machine) { described_class.new(window, 300, 3) }

  let(:start) { ChessClock::StateMachine::START }
  let(:a_run) { ChessClock::StateMachine::A_RUN }
  let(:b_run) { ChessClock::StateMachine::B_RUN }
  let(:a_pause) { ChessClock::StateMachine::A_PAUSE }

  it "adds nothing to either clock before the first move" do
    machine.state = start
    expect([machine.timer_a.time, machine.timer_b.time]).to eq([300_000_000, 300_000_000])
  end

  it "arms the delay timer at the delay" do
    machine.state = start
    expect(machine.delay_timer.time).to eq(3_000_000)
  end

  it "holds the moving player's clock still for the whole delay" do
    machine.state = a_run
    tick(1_000_000)
    tick(1_999_999)
    expect(machine.timer_a.time).to eq(300_000_000)
  end

  it "starts the clock off the delay timer's expiry, having charged nothing" do
    machine.state = a_run
    tick(3_000_000)
    tick(2_000_000)
    expect(machine.timer_a.time).to eq(298_000_000)
  end

  describe "a pause taken in the middle of the delay" do
    it "resumes with the delay that was left, not with a fresh one" do
      machine.state = a_run
      tick(1_000_000)
      machine.state = a_pause
      machine.state = a_run
      expect(machine.delay_timer.time).to eq(2_000_000)
    end

    it "still holds the clock for what is left of the delay" do
      machine.state = a_run
      tick(1_000_000)
      machine.state = a_pause
      machine.state = a_run
      tick(1_999_999)
      expect(machine.timer_a.time).to eq(300_000_000)
    end

    it "lets the clock run once that remainder is spent" do
      machine.state = a_run
      tick(1_000_000)
      machine.state = a_pause
      machine.state = a_run
      tick(2_000_000)
      tick(1_000_000)
      expect(machine.timer_a.time).to eq(299_000_000)
    end
  end

  describe "a fresh move" do
    it "restarts the delay from the top for the player now on the move" do
      machine.state = a_run
      tick(3_000_000)
      tick(2_000_000)
      machine.state = b_run
      expect(machine.delay_timer.time).to eq(3_000_000)
    end

    it "gives a full delay even when the move was handed over mid-delay" do
      machine.state = a_run
      tick(1_000_000)
      machine.state = b_run
      expect(machine.delay_timer.time).to eq(3_000_000)
    end

    it "holds the new mover's clock still while that delay runs" do
      machine.state = a_run
      tick(3_000_000)
      machine.state = b_run
      tick(2_999_999)
      expect(machine.timer_b.time).to eq(300_000_000)
    end
  end

  it "stops the delay timer while the game is paused" do
    machine.state = a_run
    tick(1_000_000)
    machine.state = a_pause
    tick(30_000_000)
    expect(machine.delay_timer.time).to eq(2_000_000)
  end

  it "never adds time to a clock, however many moves are made" do
    machine.state = a_run
    tick(3_000_000)
    tick(1_000_000)
    machine.state = b_run
    tick(3_000_000)
    tick(1_000_000)
    machine.state = a_run
    expect([machine.timer_a.time, machine.timer_b.time]).to eq([299_000_000, 299_000_000])
  end
end
