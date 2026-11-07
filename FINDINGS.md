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

The fork's flake now carries the `gsound` package on `GI_TYPELIB_PATH`
(`flake.nix`'s `typelibPath` and devShell `packages`), closing the half of this
gap that was about the typelib being absent. Re-run fresh: in `nix develop`,
`GObjectIntrospection::Loader.load("GSound", …)` resolves, `Context.new.init`
succeeds with no arguments (`GInitable#init`'s cancellable is optional through
the loader, settling the first previously-unverified question), and
`Context#play_simple` does accept a plain Ruby `Hash` where
`gsound_context_play_simple` wants a `GHashTable` (settling the second) — it
gets as far as calling into libcanberra and only then raises `GLib::Error`
("Not available"), because this sandbox's Xvfb display has no PulseAudio,
PipeWire or ALSA device for libcanberra to open. `AlertSound#emit_event` now
rescues that `GLib::Error` specifically and falls back the same way a missing
typelib does, rather than let it crash the window — before this round that
exception was unhandled and would have taken a live game down the first time
a box with the typelib but no sound hardware hit a warning threshold.

Making the typelib reachable also surfaced a second, previously-silent bug of
its own: `GObjectIntrospection::Loader` raises `NameError: private constant
…::Context::INVOKERS referenced` the second time GSound's namespace is loaded
into a *different* anonymous module in the same process, and `AlertSound`
built a fresh one per instance. Because `window.rb` builds a new
`StateMachine`, and so a new `AlertSound`, on every restart and every new
game, the real GSound route worked on a session's first alert and silently
fell back to the bell on every alert after a restart — invisible before this
round because no run had the typelib to reach that code at all. `gsound` is
now memoized on the class rather than per instance, so the namespace is built
once per process and every `AlertSound` shares it.

What is still true: the freedesktop `dialog-warning` event has not been heard
by a human from this port, because no environment this port has run in has
had both the typelib and working audio hardware at once. The call path into
GSound is now proven correct up to the sound server boundary; only "is there a
sound server, and does it actually make noise" remains unverified, which is a
property of the machine running it, not of the Ruby binding code.

**This row is substantially closed: the typelib gap and both previously-named
unknowns about the call path are resolved and committed
(`test/drive_components.rb`'s "GSound's typelib resolves and its context
inits" check, no longer a report). It stays open only in the narrow sense that
no one has run this on a box with real sound hardware and heard
`dialog-warning` play.**

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

## Resolved: the About window's release notes version (was a divergence; G12)

`src/main.py:56` passes `"0.6.0"` to `Adw.AboutWindow.new_from_appdata`, so
upstream shows the 0.6.0 release notes even though the newest `<release>` in
the metainfo is 0.6.2. An earlier round of this port set
`release_notes_version` to `"0.6.2"` instead, reasoning that it matched the
metainfo rather than upstream's apparently-stale argument — but that made the
port's About window show different release notes than upstream's own, which
is the wrong kind of "more correct" for a port whose job is to match upstream,
not to patch it. `about_dialog.rb`'s `RELEASE_NOTES_VERSION` and
`RELEASE_NOTES` now reproduce upstream's `"0.6.0"` and its notes byte for
byte; `AboutDialog::VERSION` (what `new_from_appdata` sets from the metainfo's
*newest* release) is unaffected and stays `"0.6.2"`.

## Resolved: two invented link titles with no msgid (T3)

A previous round read `AdwAboutDialog` as having no property for
`<url type="translate">` or `<url type="contribute">`, and added the two as
links titled `_("Translate")` / `_("Contribute")` — English literals with no
msgid in any of the 42 catalogues. That diagnosis was half right: libadwaita's
`new_from_appdata` genuinely has no way to set those two URLs. But its own
documentation (`Adw-1.gir`, `adw-about-dialog.c:2131`) says exactly which five
things it reads from the appdata file — `<name>`, `<id>`, `<developer>`, the
latest release's version, `<url type="homepage">`, `<url type="help">` and
`<url type="bugtracker">`, plus release notes — and neither `translate` nor
`contribute` is among them. There is no "Other Links" section built from
appdata at all in this libadwaita. So upstream's own About window, built
through this same constructor, never shows a Translate or Contribute link
either; the port wasn't missing a feature of `new_from_appdata`, it was
adding one upstream doesn't have. Both links are removed rather than
retitled.

## Resolved: the application id

An earlier round changed `APP_ID` to `org.rubygtkproject.ChessClock` with no
note anywhere, detaching the port from the desktop entry, the D-Bus name, the
GSettings path and the icon name every one of upstream's installed files is
keyed on — including the icon its own About window asks for. It is
`eu.fortysixandtwo.chessclock` again, which is upstream's, and `data/` now
carries the files keyed on it.

## Still to carry over from upstream's build

`meson.build`'s `data` and `po` subdirs do more than `rake data` does:
`desktop-file-validate` and `appstream-util validate` (**G10**). The gettext
`.pot` regeneration from `po/POTFILES.in` is no longer on this list — `rake
pot` now does it, for every `.rb` file in that list
(`spec/chess_clock/pot_spec.rb` pins the eight shortcut titles and three
a11y labels it extracts). `rake locale`, `rake gschema`, `rake pot` and `rake
install:data` cover extraction, compilation and installation; validation
does not exist, and this dev shell has neither `desktop-file-validate` nor
`appstream-util`/`appstreamcli` to run it against even if a Rake task
shelled out to them.

## Environment limitation: no GNU gettext for the two non-Ruby POTFILES.in entries

`po/POTFILES.in` names `data/eu.fortysixandtwo.chessclock.desktop.in` and the
metainfo's `.xml.in` alongside the `.rb` files. `rake pot`'s extractor
(`GetText::Tools::XGetText`, the pure-Ruby gem) falls through to its Ruby
source parser for any file none of its other parsers claim, which is
harmless — it finds no `_()`-shaped calls in a `.desktop.in` or an AppStream
`.xml.in` and extracts nothing from them — but it is not what those two files
actually need: GNU `msgfmt --desktop` and `msgfmt --xml` are the tools that
read their translatable fields (the `.desktop` `Keywords`, the metainfo's
developer credit and screenshot caption). Neither `msgfmt` (the real GNU one,
as opposed to the gem's pure-Ruby `rmsgfmt`/`GetText::Tools::MsgFmt`) nor
`intltool-extract` is in this dev shell's `PATH`; `which msgfmt
desktop-file-validate appstreamcli appstream-util intltool-extract` all fail.
Those few msgids stay uncaptured by `rake pot` until one of those tools is
added to the flake — the same shape of gap as **G10**.
