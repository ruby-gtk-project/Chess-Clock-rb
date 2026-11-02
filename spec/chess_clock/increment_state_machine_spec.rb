# frozen_string_literal: true

require "chess_clock/increment_state_machine"

require_relative "../support/machine_clock"

# Fischer increment, from ChessClockIncrementStateMachine in
# src/statemachine.py. The increment is paid at the *end* of a turn, which the
# 0.2.0 release notes call out as a deliberate change, so the player who just
# moved is the one credited.
RSpec.describe ChessClock::IncrementStateMachine do
  include MachineClock

  subject(:machine) { described_class.new(window, 300, 5) }

  let(:start) { ChessClock::StateMachine::START }
  let(:a_run) { ChessClock::StateMachine::A_RUN }
  let(:b_run) { ChessClock::StateMachine::B_RUN }

  it "puts one increment on both clocks before the first move" do
    machine.state = start
    expect([machine.timer_a.time, machine.timer_b.time]).to eq([305_000_000, 305_000_000])
  end

  it "credits the player who handed the move over, not the one receiving it" do
    machine.state = a_run
    tick(2_000_000)
    machine.state = b_run
    expect([machine.timer_a.time, machine.timer_b.time]).to eq([308_000_000, 305_000_000])
  end

  it "charges only the moving player" do
    machine.state = a_run
    tick(2_000_000)
    expect([machine.timer_a.time, machine.timer_b.time]).to eq([303_000_000, 305_000_000])
  end

  it "leaves a flagged clock at zero, so the increment cannot revive a lost game" do
    machine.state = a_run
    tick(400_000_000)
    machine.state = b_run
    expect(machine.timer_a.time).to eq(0)
  end

  it "pays nothing for a pause" do
    machine.state = a_run
    machine.state = ChessClock::StateMachine::A_PAUSE
    expect(machine.timer_a.time).to eq(305_000_000)
  end

  it "resets both clocks to one increment over the main time on a restart" do
    machine.state = a_run
    tick(10_000_000)
    machine.state = start
    expect([machine.timer_a.time, machine.timer_b.time]).to eq([305_000_000, 305_000_000])
  end
end
