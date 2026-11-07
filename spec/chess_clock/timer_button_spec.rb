# frozen_string_literal: true

require "chess_clock/timer_button"

# The clock face, from ChessClockTimerButton.on_changed in src/timerbutton.py:
# `ceil(max(time, 0) / 1_000_000)`. It rounds *up*, so a clock shows 5:00 for
# the whole of the first second and only shows 0:00 when the time is really
# gone; a face that truncated would show 0:00 for a whole second while the
# player still had time to move.
RSpec.describe ChessClock::TimerButton do
  subject(:button) { described_class.new(:white) }

  # Microseconds, as the timers count them.
  def face(time)
    button.on_changed(nil, time)
    "#{button.minutes.label}:#{button.seconds.label}"
  end

  it "rounds a part-second up" do
    expect(face(1_000_001)).to eq("0:02")
  end

  it "shows a whole five minutes at the very start of the last second of it" do
    expect(face(299_000_001)).to eq("5:00")
  end

  it "shows 0:00 only when the time is gone" do
    expect([face(1), face(0)]).to eq(["0:01", "0:00"])
  end

  it "clamps a negative time to zero rather than showing a negative clock" do
    expect(face(-5_000_000)).to eq("0:00")
  end

  it "pads the seconds to two digits" do
    expect(face(67_000_000)).to eq("1:07")
  end

  it "counts minutes past sixty rather than wrapping to hours" do
    expect(face(3_630_000_000)).to eq("60:30")
  end

  it "marks itself expired at zero and unmarks itself when time is added" do
    face(0)
    expired = button.css_classes.include?("expired")
    face(1_000_000)
    expect([expired, button.css_classes.include?("expired")]).to eq([true, false])
  end

  describe "the accessible label" do
    # The face shows digits only, so a screen reader has to be told whose clock
    # it is — and the sides swap between games. The strings themselves go
    # through gettext, so what is pinned here is that there is one per side and
    # that they differ.
    it "carries one label per side, and not the same one twice" do
      labels = described_class::ACCESSIBLE_LABELS
      expect([labels.keys, labels[:white] == labels[:black]]).to eq([[:white, :black], false])
    end

    # window.ui:214/225's static <accessibility> labels (T1), carried with
    # their own msgctxt "a11y" entries, set once at construction rather than
    # through on_white/on_black.
    it "carries a separate, distinct label per side at construction" do
      labels = described_class::INITIAL_ACCESSIBLE_LABELS
      expect([labels.keys, labels[:white] == labels[:black]]).to eq([[:white, :black], false])
    end
  end

  describe "css_name and accessible_role" do
    # timerbutton.py:53-55 calls set_css_name("button") and
    # set_accessible_role(BUTTON) on ChessClockTimerButton's own GType,
    # because a GtkWidget subclass otherwise takes a css name derived from
    # its own class. TimerButton subclasses Gtk::Button rather than
    # Gtk::Widget, so both are inherited rather than restated (G6) — pinned
    # here rather than only verified by hand, once, outside the suite (A5).
    it "has the button css name" do
      expect(button.css_name).to eq("button")
    end

    it "has the button accessible role" do
      expect(button.accessible_role).to eq(:button)
    end
  end
end
