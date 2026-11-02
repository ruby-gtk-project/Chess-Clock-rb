# frozen_string_literal: true

require "adwaita"

module ChessClock
  # AboutDialog is the about window the app.about action opens.
  #
  # Ported from ChessClockApplication.on_about_action in src/main.py. Upstream
  # builds it with Adw.AboutWindow.new_from_appdata, reading the name, summary
  # and URLs out of the metainfo compiled into its GResource, and then sets the
  # four developers, the one artist and the translator credits by hand.
  #
  # The port has no GResource to read, so the fields the appdata would have
  # supplied are set here from the same
  # data/eu.fortysixandtwo.chessclock.metainfo.xml.in: the summary becomes the
  # comments, and the homepage, issue tracker and licence are upstream's. The
  # credits are the ones upstream lists, with the port's own line added, since
  # this is a different piece of software from the Python original.
  class AboutDialog
    APPLICATION_NAME = "Chess Clock"
    APPLICATION_ICON = "eu.fortysixandtwo.chessclock"
    VERSION = "0.6.2"
    DEVELOPER_NAME = "Evangelos Ribeiro Tzaras"
    COMMENTS = "Time games of over-the-board chess."
    WEBSITE = "https://gitlab.gnome.org/World/chess-clock"
    ISSUE_URL = "https://gitlab.gnome.org/World/chess-clock/-/issues"
    COPYRIGHT = "© 2022-2025 the Chess Clock contributors"

    DEVELOPERS = [
      "Clara Hobbs",
      "Evangelos Ribeiro Tzaras",
      "gregorni",
      "Mariko Ueno",
    ].freeze

    ARTISTS = [
      "Brage Fuglseth",
    ].freeze

    # The literal msgid upstream passes through gettext: translators replace it
    # with their own names, and an untranslated build shows no credits at all.
    TRANSLATOR_CREDITS = "translator-credits"

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
      end
    end
  end
end
