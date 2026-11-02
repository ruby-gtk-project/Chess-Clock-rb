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
for a namespace with a typelib and no gem.

The fork's dev shell has no GSound typelib, so every run so far has raised
`GObjectIntrospection::RepositoryError::TypelibNotFound` and taken a fallback.
That raise was itself a crash until this round: `TypelibNotFound` descends from
`LoadError`, so from `ScriptError` and not `StandardError`, and the two
`rescue StandardError` clauses in `AlertSound` let it straight out — the first
timer to reach its warning threshold on a box without libgsound took the window
down with it. Both clauses now name `ScriptError` too, and
`test/drive_countdown.rb` runs a clock through the `alerted` signal with the
alert unmuted, which is the path that used to abort.

Two things about the GSound route itself are still unverified, because the
typelib is not there to exercise them:

1. the arity `GSound::Context#init` is exposed with — GInitable's `init` takes a
   cancellable, and whether the loader makes it optional cannot be read off the
   C declaration;
2. whether the loader accepts a Ruby `Hash` where `gsound_context_play_simple`
   wants a `GHashTable` of string to string.

`canberra-gtk-play` and `Gdk::Display#beep` are kept behind it so an alert is
never silently swallowed, and neither is the freedesktop event: the bell is a
different sound, at a different volume, through a different device, and on a
bell-disabled session it is silence.

**This row stays open until someone runs the app on a box with libgsound and
its typelib, lets a clock reach its warning threshold, and hears
`dialog-warning`.**

## Resolved: the port runs, and four bugs it was hiding

`test/drive_window.rb` and the new `test/drive_countdown.rb` both run green
under the fork's dev shell:

    nix develop --command xvfb-run -a ruby test/drive_window.rb      # 32/32
    nix develop --command xvfb-run -a ruby test/drive_countdown.rb   # 21/21

Screenshots land in `tmp/shots`. `drive_window.rb` covers both screens, both
breakpoints, the six machine signals and the five window actions;
`drive_countdown.rb` runs a two-second game down to zero, which is the only
thing that exercises `Gtk::Widget#add_tick_callback`, the alert threshold, the
`expired` signal and the red expired styling — every check in `drive_window.rb`
would pass against a frozen clock.

The first run of either found four crashes, all of them in binding calls that
`ruby -c` and a successful `require` are blind to:

- **`Gtk::Accessible#update_property` cannot be called from Ruby at all.** The
  introspection loader has no marshaller for a C array of
  `GtkAccessibleProperty` and raises `NotImplementedError: TODO: in Ruby ->
  GIArgument(array/C)[interface(enum)](GtkAccessibleProperty)` for every
  argument shape — enum constants, bare integers, a single unwrapped enum. The
  three accessible names the port sets now go through
  `lib/chess_clock/accessible_label.rb`, which writes the LABELLED_BY relation
  with `gtk_widget_add_mnemonic_label` instead; see the substitution note below.
- **`Gtk::WindowControls.new` takes its side positionally**, and refuses both a
  bare `new` and the `side:` keyword the loader's own error message advertises.
- **`Gio::SimpleAction#state` and the `change-state` argument arrive already
  unwrapped** from their `GLib::Variant`, while `state=` and `change_state`
  still want one; upstream's `get_boolean()`/`new_boolean()` pairs assume a
  variant on both sides, and the direct translation raised `undefined method
  'value' for false` the first time `win.muted` was activated.
- **`AlertSound` let `TypelibNotFound` escape**, as above.

One quirk the drivers themselves had to learn: `Gtk::Button#activate` does not
emit `clicked` inline. GtkButton's activate handler runs the pressed animation
and emits on a timeout, so a driver step that clicks and then reads the result
in the same step reads the state from before the click.

## Resolved: GSettings, with a file store behind it

Upstream reads eight keys through `Gio.Settings` against
`data/eu.fortysixandtwo.chessclock.gschema.xml`. `lib/chess_clock/settings.rb`
now does the same: `Settings::SchemaStore` is a `Gio::Settings` on that schema
id, so `gsettings get eu.fortysixandtwo.chessclock muted`, dconf and the
settings portal read and write exactly what the app does, and GSettings types
and range-checks every write.

The schema has to be found before the `Gio::Settings` is constructed —
constructing one for a schema that is not installed is a fatal `g_error` in
GLib, not an exception Ruby can catch — so `SchemaStore.open` looks the id up
in `Gio::SettingsSchemaSource.default` first and returns nil when it is absent.
What is left in that case is `Settings::FileStore`, the JSON file under
`XDG_CONFIG_HOME` the port used to have, with the same eight keys and defaults:
an uninstalled checkout still remembers its geometry and its custom control.
`Settings#store_kind` says which is live, and an explicit `path:` asks for the
file store by name, which is what the specs and the drivers use so a test run
never writes into the session's dconf.

`rake gschema` compiles the schema into `data/schemas` for a
`GSETTINGS_SCHEMA_DIR` run; `rake install:data` installs it under PREFIX.

## Substitution: accessible names through LABELLED_BY

`src/gtk/window.ui` gives `control_chooser` an
`<accessibility><property name="label">` block, and
`ChessClockTimerButton.on_white`/`on_black` call
`update_property([Gtk.AccessibleProperty.LABEL], [...])` to rename a clock face
when the sides swap. Neither route is open in Ruby: the first needs a
GtkBuilder template, and the second needs the `update_property` marshaller the
bindings do not have.

`lib/chess_clock/accessible_label.rb` sets the name through the LABELLED_BY
relation instead, with `gtk_widget_add_mnemonic_label` and a `Gtk::Label` that
is never put in the widget tree. GTK's ATContext resolves that relation to the
accessible name when no explicit LABEL property is set, so a screen reader gets
the same words — but it gets them as a *relation to a label widget* rather than
as a label property, and a tool that reads the property directly will find it
unset. Renaming means dropping the previous carrier from the relation, which is
why the carrier per widget is remembered.

## Substitution: the shortcuts window's accelerators are resolved by hand

`src/gtk/help-overlay.ui` gives each `GtkShortcutsShortcut` an `action-name`
and no accelerator, and GTK is supposed to ask the application what that action
is bound to and show the key combination beside the title. It does that in the
widget's `root` vfunc, which has already run by the time a Ruby caller holds
the window: `Gtk::Builder` roots every child as it parses, when no application
is reachable yet, and nothing re-resolves afterwards.

Measured on GTK 4.22.4 (where GtkShortcutsWindow and its parts are
deprecated), with `test/drive_components.rb` reading the labels back: setting
the window's `application` after the build, setting it as a builder property so
it is in place before the children exist, setting `transient-for`, and
re-assigning each shortcut's `action-name` all leave every accelerator empty.
Writing the `accelerator` property directly does reach the label.

`ShortcutsWindow#resolve_accelerators` therefore does the lookup GTK would have
done — `gtk_application_get_accels_for_action`, joined with a space — and sets
`accelerator` on each shortcut as the window is presented. The words and the
key combinations shown are upstream's, and they still come from the
accelerators `window.rb` and `application.rb` install rather than from a second
hand-written list, so they cannot drift from the real bindings. What differs is
only who performs the lookup. Without it the window listed six shortcuts and
not one key combination, which is most of the point of the window.

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
