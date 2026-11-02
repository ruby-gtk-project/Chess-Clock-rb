# frozen_string_literal: true

require "chess_clock/bronstein_state_machine"

require_relative "../support/machine_clock"

# Bronstein delay, from ChessClockBronsteinStateMachine in
# src/statemachine.py: the refund is min(inc - inc_timer.time, inc), so a move
# inside the delay costs nothing and a move over it costs only the excess.
#
# This is the rule-set with three interacting timers, and an off-by-one in the
# refund gives a player free time every move while still looking like a working
# clock — which is why it is tested first and hardest.
RSpec.describe ChessClock::BronsteinStateMachine do
  include MachineClock

  subject(:machine) { described_class.new(window, 300, 5) }

  let(:start) { ChessClock::StateMachine::START }
  let(:a_run) { ChessClock::StateMachine::A_RUN }
  let(:b_run) { ChessClock::StateMachine::B_RUN }

  it "puts one delay on both clocks before the first move, as upstream does" do
    machine.state = start
    expect([machine.timer_a.time, machine.timer_b.time]).to eq([305_000_000, 305_000_000])
  end

  it "starts the move timer at the delay and runs it down while a player thinks" do
    machine.state = a_run
    tick(2_000_000)
    expect(machine.inc_timer.time).to eq(3_000_000)
  end

  it "refunds the whole delay for a move that took less than it" do
    machine.state = a_run
    tick(2_000_000)
    machine.state = b_run
    expect(machine.timer_a.time).to eq(305_000_000)
  end

  it "charges only the excess for a move that took longer than the delay" do
    machine.state = a_run
    tick(8_000_000)
    machine.state = b_run
    expect(machine.timer_a.time).to eq(302_000_000)
  end

  it "caps the refund at the delay, however long the move took" do
    machine.state = a_run
    tick(60_000_000)
    machine.state = b_run
    expect(machine.timer_a.time).to eq(250_000_000)
  end

  it "resets the move timer for the player now on the move" do
    machine.state = a_run
    tick(2_000_000)
    machine.state = b_run
    expect(machine.inc_timer.time).to eq(5_000_000)
  end

  it "gives the second player the same delay the first had" do
    machine.state = a_run
    tick(2_000_000)
    machine.state = b_run
    tick(1_000_000)
    machine.state = a_run
    expect([machine.timer_a.time, machine.timer_b.time]).to eq([305_000_000, 305_000_000])
  end

  it "stops the move timer while the game is paused" do
    machine.state = a_run
    tick(1_000_000)
    machine.state = ChessClock::StateMachine::A_PAUSE
    tick(30_000_000)
    expect(machine.inc_timer.time).to eq(4_000_000)
  end

  it "does not refund a flagged clock" do
    machine.state = a_run
    tick(400_000_000)
    machine.state = b_run
    expect(machine.timer_a.time).to eq(0)
  end
end
