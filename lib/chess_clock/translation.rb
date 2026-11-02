# frozen_string_literal: true

require "gettext"

module ChessClock
  # Translation binds the `chess-clock` textdomain the 42 catalogues in po/ are
  # written against, and hands every class the `_` and `p_` markers.
  #
  # Ported from src/chess-clock.in:32-35, which calls
  # locale.bindtextdomain('chess-clock', localedir), locale.textdomain and
  # gettext.install before importing anything, and from the
  # `<translation type="gettext">chess-clock</translation>` in
  # data/eu.fortysixandtwo.chessclock.metainfo.xml.in. The domain name is
  # upstream's, so upstream's compiled catalogues answer for the port.
  #
  # `include Translation` also extends the including class, so a constant in a
  # class body can be marked the same way a method body marks one; the domain
  # is bound here, once, and found through the ancestry of whatever includes
  # this module.
  #
  # The eight `msgctxt "shortcut window"` titles and the three `msgctxt "a11y"`
  # labels are reached with `p_`, so the context upstream's .ui files set is
  # part of the lookup key here too.
  module Translation
    TEXTDOMAIN = "chess-clock"

    # A checkout that has run `rake locale` first, then the system catalogues an
    # installed gem reads. The last entry always exists, so the domain is never
    # bound without a path.
    LOCALE_PATHS = [
      ENV.fetch("CHESS_CLOCK_LOCALEDIR", nil),
      File.expand_path("../../locale", __dir__),
      "/usr/share/locale",
    ].compact.freeze

    def self.locale_path = LOCALE_PATHS.find { |dir| File.directory?(dir) } || LOCALE_PATHS.last

    def self.included(base) = base.extend(self)

    include GetText

    bindtextdomain(TEXTDOMAIN, path: locale_path)
  end
end
