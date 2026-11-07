# frozen_string_literal: true

require "chess_clock/accessible_label"

# Ported from the four places upstream sets an accessible name — see
# lib/chess_clock/accessible_label.rb's header for why LABELLED_BY stands in
# for Gtk::Accessible#update_property here.
RSpec.describe ChessClock::AccessibleLabel do
  # A bare Gtk::Widget is enough: `add_mnemonic_label`/`remove_mnemonic_label`
  # are defined on Gtk::Widget itself, below Gtk::Accessible.
  subject(:host) do
    Class.new do
      include ChessClock::AccessibleLabel
    end.new
  end

  let(:widget) { Gtk::Box.new(:horizontal, 0) }

  it "adds a label carrier as a mnemonic label of the widget" do
    host.announce(widget, "Player white timer")
    expect(widget.mnemonic_labels.map(&:label)).to eq(["Player white timer"])
  end

  it "replaces a widget's previous carrier rather than accumulating labels" do
    host.announce(widget, "Player white timer")
    host.announce(widget, "Player black timer")
    expect(widget.mnemonic_labels.map(&:label)).to eq(["Player black timer"])
  end

  it "tracks carriers per widget, not globally" do
    other = Gtk::Box.new(:horizontal, 0)
    host.announce(widget, "Player white timer")
    host.announce(other, "Player black timer")
    expect([widget.mnemonic_labels.map(&:label), other.mnemonic_labels.map(&:label)])
      .to eq([["Player white timer"], ["Player black timer"]])
  end

  it "builds a carrier that is not in any widget tree" do
    host.announce(widget, "Player white timer")
    carrier = widget.mnemonic_labels.first
    expect(carrier.parent).to be_nil
  end
end
