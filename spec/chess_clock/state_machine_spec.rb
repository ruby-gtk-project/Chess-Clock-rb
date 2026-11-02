# frozen_string_literal: true

require "chess_clock/increment_state_machine"

require_relative "../support/machine_clock"

# Upstream has no test suite; this pins the parts of
# ChessClockStateMachine (src/statemachine.py) the window depends on and
# nothing else checks — the handler bookkeeping behind disconnect_all, and the
# idle inhibit's cookie.
RSpec.describe ChessClock::StateMachine do
  include MachineClock

  # The base class never runs on its own — the window always builds one of the
  # three rule-sets — so the increment machine with a zero increment is the
  # plain state machine's behaviour.
  subject(:machine) { ChessClock::IncrementStateMachine.new(window, 300, 0) }

  let(:button_a) { Fakes::Button.new }
  let(:button_b) { Fakes::Button.new }

  describe "state assignment" do
    it "starts in START with both clocks full and nothing to pause" do
      pauses = []
      machine.connect(:pause) { |_machine, active, paused| pauses << [active, paused] }
      machine.state = ChessClock::StateMachine::START
      expect([machine.timer_a.time, machine.timer_b.time, pauses]).to eq([300_000_000, 300_000_000, [[false, false]]])
    end

    it "runs the hook before recording the new state, so a hook sees the old one" do
      machine.state = ChessClock::StateMachine::A_RUN
      seen = []
      machine.connect(:awbb) { seen << machine.state }
      machine.state = ChessClock::StateMachine::B_RUN
      # awbb is only emitted out of START, so a second run emits nothing.
      expect([seen, machine.state]).to eq([[], ChessClock::StateMachine::B_RUN])
    end

    it "names A white when A moves first, and B white when B moves first" do
      machine.add_a_button(button_a)
      machine.add_b_button(button_b)
      machine.state = ChessClock::StateMachine::A_RUN
      expect([button_a.whites.size, button_b.blacks.size]).to eq([1, 1])
    end
  end

  describe "the clicks" do
    it "hands the move over: tapping A's half starts B" do
      machine.add_a_button(button_a)
      machine.state = ChessClock::StateMachine::A_RUN
      button_a.click
      expect(machine.state).to eq(ChessClock::StateMachine::B_RUN)
    end

    it "pauses the running side and resumes it" do
      machine.state = ChessClock::StateMachine::A_RUN
      machine.on_pause_clicked
      paused = machine.state
      machine.on_pause_clicked
      expect([paused, machine.state]).to eq([ChessClock::StateMachine::A_PAUSE, ChessClock::StateMachine::A_RUN])
    end
  end

  describe "#disconnect_all" do
    # The buttons outlive the machine driving them: the window throws a machine
    # away whenever a new game starts. A handler left behind would drive the
    # dead machine from a live button.
    it "removes the machine's own handlers" do
      machine.add_a_button(button_a)
      machine.state = ChessClock::StateMachine::A_RUN
      machine.disconnect_all
      machine.state = ChessClock::StateMachine::B_RUN
      expect(button_a.actives.size).to eq(1)
    end

    it "removes the handlers it installed on both timers" do
      machine.add_a_button(button_a)
      machine.add_b_button(button_b)
      machine.disconnect_all
      machine.timer_a.increment(1_000_000)
      machine.timer_b.increment(1_000_000)
      expect([button_a.changes, button_b.changes]).to eq([[], []])
    end

    it "removes both buttons' clicked handlers, by their GTK handler ids" do
      machine.add_a_button(button_a)
      machine.add_b_button(button_b)
      machine.state = ChessClock::StateMachine::A_RUN
      machine.disconnect_all
      button_a.click
      button_b.click
      expect([machine.state, button_a.disconnected.size, button_b.disconnected.size]).to eq(
        [ChessClock::StateMachine::A_RUN, 1, 1],
      )
    end

    it "is safe to call twice" do
      machine.add_a_button(button_a)
      machine.disconnect_all
      expect { machine.disconnect_all }.not_to raise_error
    end
  end

  describe "the idle inhibit" do
    it "is taken once per run streak, not once per move" do
      machine.state = ChessClock::StateMachine::A_RUN
      machine.state = ChessClock::StateMachine::B_RUN
      machine.state = ChessClock::StateMachine::A_RUN
      expect(app.inhibited.size).to eq(1)
    end

    it "names the session reason the screen stays awake for" do
      machine.state = ChessClock::StateMachine::A_RUN
      expect(app.inhibited.first.last).to eq("Game clock running")
    end

    it "is released on a pause and taken again on resume" do
      machine.state = ChessClock::StateMachine::A_RUN
      machine.state = ChessClock::StateMachine::A_PAUSE
      machine.state = ChessClock::StateMachine::A_RUN
      expect([app.uninhibited, app.inhibited.size]).to eq([[1], 2])
    end

    it "is released when a new game starts" do
      machine.state = ChessClock::StateMachine::A_RUN
      machine.state = ChessClock::StateMachine::START
      expect(app.uninhibited).to eq([1])
    end

    it "is not released twice over" do
      machine.state = ChessClock::StateMachine::A_RUN
      machine.state = ChessClock::StateMachine::A_PAUSE
      machine.state = ChessClock::StateMachine::START
      expect(app.uninhibited).to eq([1])
    end
  end

  describe "the mute flag" do
    it "silences the alert the timers ask for" do
      machine.muted = true
      expect(machine.muted).to be(true)
    end
  end
end
