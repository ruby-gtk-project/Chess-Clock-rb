# frozen_string_literal: true

require "chess_clock/signals"

# Pins the two GObject conventions ChessClock::Signals exists to keep, because
# the whole port is wired through them: a handler is called with the emitter
# first, and `connect` returns an id `disconnect` undoes.
RSpec.describe ChessClock::Signals do
  subject(:emitter) { Class.new { include ChessClock::Signals }.new }

  it "calls the handler with the emitter first and the arguments after it" do
    seen = []
    emitter.connect(:changed) { |source, time| seen << [source, time] }
    emitter.emit(:changed, 42)
    expect(seen).to eq([[emitter, 42]])
  end

  it "accepts a Method object as well as a block" do
    seen = []
    emitter.connect(:changed, ->(_source, time) { seen << time })
    emitter.emit(:changed, 7)
    expect(seen).to eq([7])
  end

  it "calls only the handlers connected to the signal emitted" do
    seen = []
    emitter.connect(:changed) { seen << :changed }
    emitter.connect(:expired) { seen << :expired }
    emitter.emit(:expired)
    expect(seen).to eq([:expired])
  end

  it "calls every handler connected to the same signal" do
    seen = []
    emitter.connect(:changed) { seen << :first }
    emitter.connect(:changed) { seen << :second }
    emitter.emit(:changed)
    expect(seen).to eq([:first, :second])
  end

  it "returns distinct ids, and disconnect silences exactly one of them" do
    seen = []
    first = emitter.connect(:changed) { seen << :first }
    second = emitter.connect(:changed) { seen << :second }
    emitter.disconnect(first)
    emitter.emit(:changed)
    expect([first == second, seen]).to eq([false, [:second]])
  end

  it "treats a string and a symbol signal name as the same signal" do
    seen = []
    emitter.connect("changed") { seen << :called }
    emitter.emit(:changed)
    expect(seen).to eq([:called])
  end
end
