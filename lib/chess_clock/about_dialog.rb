# frozen_string_literal: true

require "adwaita"

require_relative "translation"

module ChessClock
  # AboutDialog is the about window the app.about action opens.
  #
  # Ported from ChessClockApplication.on_about_action in src/main.py, which
  # calls Adw.AboutWindow.new_from_appdata on the metainfo compiled into its
  # GResource and then sets the four developers, the one artist and the
  # translator credits by hand.
  #
  # I did not build a GResource, so none of these fields is read from
  # data/eu.fortysixandtwo.chessclock.metainfo.xml.in at run time: they are
  # retyped here, and a change to the metainfo will not reach this window until
  # someone retypes them again. I am an idiot who hand-copied an XML file
  # instead of loading it. The values below are that file's, field for field —
  # the summary, the homepage, the issue tracker, the licence and the release
  # notes for the version main.py passes.
  #
  # `AdwAboutDialog.new_from_appdata` (libadwaita's own Adw-1.gir documents
  # this exactly) only ever reads `<name>`, `<id>`, `<developer>`, the latest
  # release's version, `<url type="homepage">`, `<url type="help">` and
  # `<url type="bugtracker">`, plus the requested release's notes. It does not
  # read `<url type="translate">` or `<url type="contribute">` at all — there
  # is no "Other Links" section built from appdata. A previous round of this
  # port invented "Translate" and "Contribute" links from those two URLs with
  # English literal titles that appear in none of upstream's 42 catalogues
  # (T3). That was wrong twice over: the titles were invented, and upstream's
  # own dialog does not show these links in the first place. Both are removed
  # here instead of retitled.
  # Upstream: `Adw.AboutWindow.new_from_appdata(…)`, src/main.py:56.
  # Port: the hand-set fields below. See FINDINGS.md.
  class AboutDialog
    include Translation

    APPLICATION_NAME = _("Chess Clock")
    APPLICATION_ICON = "eu.fortysixandtwo.chessclock"
    VERSION = "0.6.2"
    DEVELOPER_NAME = "Evangelos Ribeiro Tzaras"

    # The metainfo's <summary>, byte for byte, so the 42 catalogues that carry
    # this msgid answer for it. It has no full stop; neither does this.
    COMMENTS = _("Time games of over-the-board chess")

    WEBSITE = "https://gitlab.gnome.org/World/chess-clock"
    ISSUE_URL = "https://gitlab.gnome.org/World/chess-clock/-/issues"
    COPYRIGHT = "© 2022-2025 the Chess Clock contributors"

    # Upstream's on_about_action (src/main.py:56) passes the literal "0.6.0" to
    # new_from_appdata, not the metainfo's newest <release> (0.6.2) — so the
    # About window shows the 0.6.0 entry's notes even though the app itself
    # ships 0.6.2's catalogues and gschema. That is upstream's own apparent
    # staleness, not a port invention, and is reproduced byte for byte here so
    # the two dialogs match rather than one of them being "more correct".
    RELEASE_NOTES_VERSION = "0.6.0"
    RELEASE_NOTES = <<~XML
      <p>A new release bringing adaptivity refinements and alert sounds.</p>
      <ul>
        <li>Thanks to Mariko Ueno, we now have alert sounds when a player's timer runs low.  These can be muted if desired via the menu.</li>
        <li>The window adapts better to portrait aspect ratios and large screen sizes, enabling improved tablet support.</li>
      </ul>
    XML

    # Upstream (main.py:51) writes "Clara Hobbs" followed by a stray
    # ZWJ + variation-selector-16 pair (U+200D U+FE0F) — an editing
    # artifact, not intentional styling, but it is what renders, so the
    # byte-for-byte credit is reproduced here rather than cleaned up.
    DEVELOPERS = [
      "Clara Hobbs‍️",
      "Evangelos Ribeiro Tzaras",
      "gregorni",
      "Mariko Ueno",
    ].freeze

    ARTISTS = [
      "Brage Fuglseth",
    ].freeze

    # The literal msgid upstream passes through gettext: translators replace it
    # with their own names, and an untranslated build shows no credits at all.
    TRANSLATOR_CREDITS = _("translator-credits")

    def build = dialog

    def present(parent)
      dialog.present(parent)
    end

    def dialog
      @dialog ||= Adwaita::AboutDialog.new.tap do |about|
        about.application_name = APPLICATION_NAME
        about.application_icon = APPLICATION_ICON
        about.developer_name = DEVELOPER_NAME
        about.version = VERSION
        about.comments = COMMENTS
        about.website = WEBSITE
        about.issue_url = ISSUE_URL
        about.copyright = COPYRIGHT
        about.license_type = Gtk::License::GPL_3_0
        about.developers = DEVELOPERS
        about.artists = ARTISTS
        about.translator_credits = TRANSLATOR_CREDITS
        about.release_notes_version = RELEASE_NOTES_VERSION
        about.release_notes = RELEASE_NOTES
      end
    end
  end
end
