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
  # the summary, the homepage, the issue tracker, the licence, the release
  # notes of the newest `<release>`, and the translate and contribute URLs,
  # which AdwAboutDialog has no property for and which are therefore added as
  # links.
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

    # <releases>' newest entry in data/eu.fortysixandtwo.chessclock.metainfo.xml.in.
    RELEASE_NOTES_VERSION = "0.6.2"
    RELEASE_NOTES = <<~XML
      <p>A bugfix release under new maintainership.</p>
      <ul>
        <li>Fix timer display in RTL languages, thanks to Yosef Or Boczko</li>
        <li>New and updated translations.</li>
      </ul>
    XML

    # <url type="translate"> and <url type="contribute">. AdwAboutDialog has
    # properties for the homepage, the issue tracker and support, and none for
    # these two, so they go in its "Other links" section.
    LINKS = [
      [_("Translate"), "https://l10n.gnome.org/module/chess-clock/"],
      [_("Contribute"), "https://gitlab.gnome.org/World/chess-clock/-/blob/main/CONTRIBUTING.md"],
    ].freeze

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
        LINKS.each { |title, url| about.add_link(title, url) }
      end
    end
  end
end
