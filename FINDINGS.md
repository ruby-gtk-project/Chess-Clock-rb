# Findings

Engineering notes for the Ruby port of Chess Clock: binding gaps, substitutions
and the one or two places the port's shape differs from upstream's.

Nothing in this file closes a gap. A binding limitation is evidence that a gap
is expensive to close; it is never evidence that it is closed. Every item below
that corresponds to a missing or substituted behaviour stays a gap in
`.reports/component-parity.md`, and the sentence in the source that describes
it says only that the writer did not build it.

## Open: the alert sound does not demonstrably play

`src/statemachine.py:54-66` builds a `GSound.Context`, calls `init()` on it,
and on every `alerted` signal plays
`{ATTR_EVENT_ID: "dialog-warning", ATTR_CANBERRA_VOLUME: "1"}`.

GSound ships a GIR typelib but has no ruby-gnome binding gem.
`lib/chess_clock/alert_sound.rb` therefore loads the namespace through
`GObjectIntrospection::Loader.load("GSound", …)`, which is the documented route
for a namespace with a typelib and no gem. Three things about that route are
unverified, because the `gtk4`, `adwaita` and `gobject-introspection` gems are
not installable in the shell the port was written in:

1. whether the loader resolves the `GSound` namespace at all on a box that has
   `libgsound` and its typelib installed;
2. the arity `GSound::Context#init` is exposed with — GInitable's `init` takes a
   cancellable, and whether the loader makes it optional cannot be read off the
   C declaration;
3. whether the loader accepts a Ruby `Hash` where `gsound_context_play_simple`
   wants a `GHashTable` of string to string.

`canberra-gtk-play` and `Gdk::Display#beep` are kept behind it so an alert is
never silently swallowed, and neither is the freedesktop event: the bell is a
different sound, at a different volume, through a different device, and on a
bell-disabled session it is silence.

**This row stays open until someone runs the app, lets a clock reach its
warning threshold, and hears `dialog-warning`.** Rendering and driving did not
happen this round either, for the same missing gems.

## Open: nothing has been rendered or driven

`test/drive_window.rb` exists and exercises both screens, both breakpoints, the
six machine signals and the five window actions, but it has never been run —
the gems are not installed. Three binding-risk points are unverified as a
result:

- `Gtk::Widget#add_tick_callback`'s block arity (`lib/chess_clock/timer.rb:48`).
- `Adwaita::BreakpointCondition.parse` plus `add_breakpoint`
  (`lib/chess_clock/window.rb`, `lib/chess_clock/timer_button.rb`).
- `update_property` with a `GLib::Value` for accessible labels
  (`lib/chess_clock/window.rb`, `lib/chess_clock/timer_button.rb`).

The breakpoint steps in the driver resize the window by assigning
`default_width`, which is the one step whose *trigger* is itself in doubt: GTK
ignores a default size on a window that is already mapped, so if the narrow
layout does not apply, suspect the driver before the breakpoint.

## Substitution: GSettings replaced by a JSON file

Upstream reads eight keys through `Gio.Settings` against
`data/eu.fortysixandtwo.chessclock.gschema.xml`. `lib/chess_clock/settings.rb`
keeps the same eight keys, types and defaults in a JSON file under
`XDG_CONFIG_HOME`, so `gsettings`, dconf and the settings portal cannot see
them and nothing range-checks a value.

The schema itself is now carried in `data/`, and `rake gschema` compiles it;
the application does not yet read through it. This is a gap, not a design.

## Substitution: no GResource

Upstream compiles `src/gtk/*.css`, the four `.ui` templates and the metainfo
into `chess-clock.gresource` and lets GTK and libadwaita find them by resource
path. The port has no resource bundle, with three consequences:

- `lib/chess_clock/style.rb` inlines both stylesheets and installs them on the
  display by hand, including the high-contrast switch GTK would make itself.
- `lib/chess_clock/about_dialog.rb` sets by hand what
  `Adw.AboutWindow.new_from_appdata` would read from the metainfo.
- `lib/chess_clock/shortcuts_window.rb` carries `help-overlay.ui` as a heredoc.

## Substitution: plain Ruby models instead of GObjects

`Timer` and `StateMachine` are `GObject.Object`s upstream, with
`@GObject.Property` on `ChessClockStateMachine.muted` and
`ChessClockTimerButton.inverted`. In the port they are plain Ruby objects with
`ChessClock::Signals` supplying `connect`/`emit`/`disconnect`, so neither
property can be bound by an `AdwBreakpoint` setter, a `GtkExpression` or
`Gio.Settings.bind`. The breakpoint sets `inverted` by hand instead.

## Substitution: GtkBuilder's translatable properties

`src/gtk/help-overlay.ui` marks its eight shortcut titles
`translatable="yes" context="shortcut window"`, and GtkBuilder resolves such a
property through `dgettext` in C against the builder's translation domain.
ruby-gettext is pure Ruby and binds nothing in C, so a title marked that way
inside the port's heredoc would be English in all 42 languages.

The titles are therefore looked up in Ruby, with upstream's `msgctxt`, and
interpolated into the description already translated and XML-escaped. The same
`.po` entries answer for them; what changed is which library does the lookup.

## Divergence: where the frame-clock callbacks are installed

Upstream installs both timers' frame-clock callbacks in
`ChessClockWindow.__init__`. In the port each `Timer` installs its own when it
starts running and removes it by returning false when it stops, so there is one
callback per running clock. Upstream's second registration looks redundant;
"looks redundant" is not a test, and neither shape is under one.

## Divergence: the About window's release notes version

`src/main.py:56` passes `"0.6.0"` to `Adw.AboutWindow.new_from_appdata`, so
upstream shows the 0.6.0 release notes although the newest `<release>` in the
metainfo is 0.6.2. The port sets `release_notes_version` to `"0.6.2"` and
carries that release's notes, which matches the metainfo rather than upstream's
stale argument.

## Divergence: two link titles with no msgid

`AdwAboutDialog` has properties for the homepage, the issue tracker and
support, and none for `<url type="translate">` or `<url type="contribute">`, so
the port adds those two as links. Their titles — "Translate" and "Contribute" —
are the port's own strings: they are marked for translation but have no msgid
in any of the 42 catalogues, because upstream never needed one.

## Resolved: the application id

An earlier round changed `APP_ID` to `org.rubygtkproject.ChessClock` with no
note anywhere, detaching the port from the desktop entry, the D-Bus name, the
GSettings path and the icon name every one of upstream's installed files is
keyed on — including the icon its own About window asks for. It is
`eu.fortysixandtwo.chessclock` again, which is upstream's, and `data/` now
carries the files keyed on it.

## Still to carry over from upstream's build

`meson.build`'s `data` and `po` subdirs do more than `rake data` does:
`desktop-file-validate`, `appstream-util validate`, and the gettext
`.pot` regeneration from `po/POTFILES.in`. `rake locale`, `rake gschema` and
`rake install:data` cover compilation and installation only.
