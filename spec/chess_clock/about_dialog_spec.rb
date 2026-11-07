# frozen_string_literal: true

require "chess_clock/about_dialog"

# Ported from ChessClockApplication.on_about_action in src/main.py, which
# builds an Adw.AboutWindow from the compiled metainfo and sets the
# developers/artist/translator credits by hand — see about_dialog.rb's header
# for why those fields are retyped from the metainfo here (G3) and why
# Translate/Contribute links are not invented (T3).
RSpec.describe ChessClock::AboutDialog do
  subject(:about) { described_class.new }

  it "builds an Adwaita about dialog" do
    expect(about.build).to be_a(Adwaita::AboutDialog)
  end

  it "memoizes the dialog across #build and #dialog" do
    expect(about.build).to equal(about.dialog)
  end

  it "sets the application name, icon and version from the metainfo" do
    dialog = about.build
    expect([dialog.application_name, dialog.application_icon, dialog.version]).to eq(
      ["Chess Clock", "eu.fortysixandtwo.chessclock", "0.6.2"],
    )
  end

  it "lists upstream's four developers, byte for byte including the stray ZWJ+VS16 pair" do
    expect(about.build.developers).to eq(
      [
        "Clara Hobbs‍️",
        "Evangelos Ribeiro Tzaras",
        "gregorni",
        "Mariko Ueno",
      ],
    )
  end

  it "lists upstream's one artist" do
    expect(about.build.artists).to eq(["Brage Fuglseth"])
  end

  it "sets GPL-3.0 as the licence" do
    expect(about.build.license_type).to eq(Gtk::License::GPL_3_0)
  end

  it "passes the translator-credits constant through untouched" do
    # TRANSLATOR_CREDITS is translated at class-load time (T3's msgid), so a
    # suite that has changed the process locale by the time this spec runs
    # must compare against the constant itself and not the English literal.
    expect(about.build.translator_credits).to eq(described_class::TRANSLATOR_CREDITS)
  end

  it "shows upstream's release-notes version, 0.6.0, and not the port's own version" do
    dialog = about.build
    expect([dialog.release_notes_version, dialog.version]).to eq(["0.6.0", "0.6.2"])
  end

  it "sets the homepage and issue tracker upstream's dialog has" do
    dialog = about.build
    expect([dialog.website, dialog.issue_url]).to eq(
      [
        "https://gitlab.gnome.org/World/chess-clock",
        "https://gitlab.gnome.org/World/chess-clock/-/issues",
      ],
    )
  end

  describe "#present" do
    it "presents the dialog for the given parent without raising" do
      window = Gtk::Window.new
      expect { about.present(window) }.not_to raise_error
    end
  end
end
