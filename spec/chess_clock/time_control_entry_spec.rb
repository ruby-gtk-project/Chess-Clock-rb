# frozen_string_literal: true

require "tmpdir"

require "chess_clock/settings"
require "chess_clock/time_control_entry"

# The seconds spin button's wrap, from ChessClockTimeControlEntry in
# src/timecontrolentry.py. GTK wraps the value first and then emits "wrapped",
# so the handler has to infer which way it went from where it landed: 59 means
# it came down past zero and a minute is owed back, anything at or under 30
# means it went up past 59 and a minute is carried.
#
# Inverted, the custom control silently sets a game two minutes away from the
# one the player asked for, which is why this is worth a spec of its own.
RSpec.describe ChessClock::TimeControlEntry do
  subject(:entry) { described_class.new(settings) }

  around do |example|
    Dir.mktmpdir do |dir|
      @path = File.join(dir, "settings.json")
      example.run
    end
  end

  let(:settings) { ChessClock::Settings.new(path: @path) }

  describe "#on_seconds_wrapped" do
    it "borrows a minute when the seconds wrap down past zero" do
      entry.minutes_adjustment.value = 5
      entry.seconds_adjustment.value = 59
      entry.on_seconds_wrapped
      expect(entry.minutes_adjustment.value).to eq(4)
    end

    it "carries a minute when the seconds wrap up past fifty-nine" do
      entry.minutes_adjustment.value = 5
      entry.seconds_adjustment.value = 0
      entry.on_seconds_wrapped
      expect(entry.minutes_adjustment.value).to eq(6)
    end

    it "treats thirty as a carry and thirty-one as a borrow" do
      entry.minutes_adjustment.value = 5
      entry.seconds_adjustment.value = 30
      entry.on_seconds_wrapped
      carried = entry.minutes_adjustment.value
      entry.minutes_adjustment.value = 5
      entry.seconds_adjustment.value = 31
      entry.on_seconds_wrapped
      expect([carried, entry.minutes_adjustment.value]).to eq([6, 4])
    end
  end

  describe "#control" do
    it "reports the total main time in seconds and the increment" do
      entry.minutes_adjustment.value = 5
      entry.seconds_adjustment.value = 30
      entry.increment_adjustment.value = 3
      expect(entry.control).to eq([330, 3])
    end
  end

  describe "#set_control" do
    it "fills the three spin buttons in from a preset rather than starting a game" do
      entry.set_control(described_class::PRESETS.last)
      expect(entry.control).to eq([1800, 20])
    end

    it "offers the eight presets upstream lays out, column first" do
      expect(described_class::PRESETS.map { |preset| preset[:label] }).to eq(
        ["1+0", "2+1", "5+0", "5+3", "10+0", "10+5", "30+0", "30+20"],
      )
    end
  end

  describe "#on_seconds_output" do
    it "renders the seconds two digits wide, so the pair reads as one clock" do
      entry.seconds_adjustment.value = 7
      entry.on_seconds_output
      expect(entry.seconds.text).to eq("07")
    end
  end
end
