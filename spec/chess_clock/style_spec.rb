# frozen_string_literal: true

require "chess_clock/style"

# Ported from src/gtk/style.css and src/gtk/style-hc.css, inlined here rather
# than compiled into a GResource (G3) — see style.rb's header.
RSpec.describe ChessClock::Style do
  subject(:style) { described_class.new }

  it "builds a CSS provider from the main stylesheet" do
    expect(style.provider).to be_a(Gtk::CssProvider)
  end

  it "memoizes the main provider across calls" do
    expect(style.provider).to equal(style.provider)
  end

  it "builds a separate CSS provider for the high-contrast sheet" do
    expect(style.high_contrast_provider).to be_a(Gtk::CssProvider)
    expect(style.high_contrast_provider).not_to equal(style.provider)
  end

  it "carries every class the timer button and window rely on" do
    %w[timerbutton expired inverted large colon custom-label time-button custom-spin transparent].each do |class_name|
      expect(described_class::STYLE).to include(".#{class_name}")
    end
  end

  it "overrides only the four timer-button background colours in high contrast" do
    rules = described_class::HIGH_CONTRAST.scan(/\.([\w-]+(?:\.[\w-]+)*)\s*\{/).flatten
    expect(rules.sort).to eq(["timerbutton.black", "timerbutton.expired.black", "timerbutton.expired.white", "timerbutton.white"].sort)
  end

  describe "#load" do
    it "returns itself" do
      expect(style.load(display: nil)).to equal(style)
    end

    it "does nothing when there is no display, rather than raising" do
      expect { style.load(display: nil) }.not_to raise_error
    end

    it "installs both providers on a real display" do
      display = Gdk::Display.open(ENV.fetch("DISPLAY", ":0"))
      expect { style.load(display: display) }.not_to raise_error
    end
  end

  it "reads the live style manager's high-contrast state through Adwaita" do
    expect(style.style_manager).to be_a(Adwaita::StyleManager)
  end
end
