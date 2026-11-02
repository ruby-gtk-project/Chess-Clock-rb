# Changelog

[![SemVer 2.0.0][📌semver-img]][📌semver] [![Keep-A-Changelog 1.0.0][📗keep-changelog-img]][📗keep-changelog]

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][📗keep-changelog],
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html),
and [yes][📌major-versions-not-sacred], platform and engine support are part of the [public API][📌semver-breaking].
Please file a bug if you notice a violation of semantic versioning.

[📌semver]: https://semver.org/spec/v2.0.0.html
[📌semver-img]: https://img.shields.io/badge/semver-2.0.0-FFDD67.svg?style=flat
[📌semver-breaking]: https://github.com/semver/semver/issues/716#issuecomment-869336139
[📌major-versions-not-sacred]: https://tom.preston-werner.com/2022/05/23/major-version-numbers-are-not-sacred.html
[📗keep-changelog]: https://keepachangelog.com/en/1.0.0/
[📗keep-changelog-img]: https://img.shields.io/badge/keep--a--changelog-1.0.0-FFDD67.svg?style=flat

## [Unreleased]

### Added
- `data/`, carried over from upstream: the desktop entry, the D-Bus service
  file, the AppStream metainfo, the GSettings schema and the four icons
- `po/`, carried over from upstream unchanged: 42 catalogues against the
  `chess-clock` textdomain, plus a `POTFILES.in` listing the port's own files
- `ChessClock::Translation`, which binds that textdomain, and gettext markers
  on the 40 msgids in `lib/`
- Rakefile tasks `locale`, `gschema`, `data` and `install:data`
- Runtime dependencies on gtk4, adwaita, gio2 and gettext
- The About window's release notes, translate and contribute links
- `lib/chess/clock/rb.rb`, so the suite loads, and nine specs plus
  `test/drive_window.rb`
- `FINDINGS.md`

### Changed
- `APP_ID` is `eu.fortysixandtwo.chessclock` again, which is upstream's and
  which every file in `data/` is keyed on
- `ChessClock::Application#run` passes `ARGV` through, as `src/main.py:85` does
- The About window's `comments` is the metainfo's summary byte for byte,
  without the full stop that broke the msgid match
- The alert sound plays the freedesktop `dialog-warning` event through GSound,
  loaded from its typelib; see `FINDINGS.md` for what is still unverified

### Deprecated

### Removed
- The dead `TimeControlEntry#get_control` alias

### Fixed

### Security

[Unreleased]: https://gitlab.com/ruby-gtk-project/Chess-Clock-rb/-/compare/HEAD
