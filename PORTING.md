# Porting status

Resume point for the next run. Factual only: a row here says what exists, not
what is nearly done. The authoritative detail lives in `.reports/`; this file
is the index to it.

## Upstream

Chess Clock is a GNOME game clock: you pick a time control (preset or custom,
with Fischer increment, Bronstein delay or simple delay), then tap each
player's half of the window to hand over the move while their clock counts
down.

It is implemented in Python 3 with PyGObject (GTK 4 / libadwaita 1.4), with the
UI in GtkBuilder `.ui` templates compiled into a GResource. The spec lives on
the `origin/main` ref of this repository — read it with
`git show origin/main:<path>` and `git ls-tree -r --name-only origin/main`.
`origin/main` is never checked out and never merged; the port on `ruby` is
written from scratch against it.

## Done

Components implemented and believed complete. "Believed" is load-bearing:
nothing in this column has been executed (see **TP1** under Open gaps).

| Port | Upstream |
|---|---|
| `lib/chess_clock.rb` | `src/__init__.py` (require graph) |
| `lib/chess_clock/application.rb` | `src/main.py` |
| `lib/chess_clock/about_dialog.rb` | `src/main.py` (`on_about_action`) |
| `lib/chess_clock/primary_menu.rb` | `src/gtk/window.ui` (`<menu>`) |
| `lib/chess_clock/window.rb` | `src/window.py` + `src/gtk/window.ui` |
| `lib/chess_clock/timer.rb` | `src/timer.py` |
| `lib/chess_clock/timer_button.rb` | `src/timerbutton.py` + `src/gtk/timerbutton.ui` |
| `lib/chess_clock/time_control_entry.rb` | `src/timecontrolentry.py` + `src/gtk/timecontrolentry.ui` |
| `lib/chess_clock/state_machine.rb` | `src/statemachine.py` (`ChessClockStateMachine`) |
| `lib/chess_clock/increment_state_machine.rb` | `src/statemachine.py` (Fischer increment) |
| `lib/chess_clock/bronstein_state_machine.rb` | `src/statemachine.py` (Bronstein delay) |
| `lib/chess_clock/delay_state_machine.rb` | `src/statemachine.py` (simple delay) |
| `lib/chess_clock/alert_sound.rb` | `src/statemachine.py` (`GSound.Context`) |
| `lib/chess_clock/signals.rb` | `GObject.Object` signal/property machinery |
| `lib/chess_clock/shortcuts_window.rb` | `src/gtk/help-overlay.ui` |
| `lib/chess_clock/style.rb` | `src/gtk/style.css`, `src/gtk/style-hc.css` |
| `lib/chess_clock/settings.rb` | `data/eu.fortysixandtwo.chessclock.gschema.xml` |
| `lib/chess_clock/translation.rb` | gettext textdomain binding |
| `exe/chess-clock` | `src/chess-clock.in` |
| `data/` (4 files) | `data/` — byte-identical to upstream |
| `po/` (42 locales + `LINGUAS`, `POTFILES.in`) | `po/` |

Specs exist for 10 of the 18 units, 145 cases, none of them ever run.

## Not started

Upstream components with no Ruby counterpart at all.

| Upstream | Note |
|---|---|
| `src/chess-clock.gresource.xml` | no resource bundle on the port; CSS, the help overlay and the metainfo are retyped in Ruby instead (**G3**) |
| `COPYING` | GPL-3 licence text, absent from a GPL-3 derivative (**G8**) |
| `CONTRIBUTING.md` | absent; the About window's Contribute link points at upstream's (**G8**) |
| `chess-clock.doap` | GNOME project metadata (**G9**) |
| `eu.fortysixandtwo.chessclock.json` | Flatpak manifest (**G9**) |
| `data/meson.build` validation | `desktop-file-validate`, `appstream-util validate` (**G10**) |
| `po/meson.build` `.pot` regeneration | no gettext extraction path on `ruby` (**G10**, **T2**) |
| `src/meson.build`, `meson.build` | build system replaced by `Rakefile` + gemspec; compile/install only, no validation |

## Open gaps

The last audit reported **18 gaps** and **clean = false**. Breakdown by report:

- `.reports/component-parity.md` — **G1**–**G11** (11): activate handler
  rebuilds the window instead of raising the open one (**G1**); JSON file
  instead of GSettings (**G2**); no GResource (**G3**); `Timer`/`StateMachine`
  are plain Ruby, not GObjects, so `muted` and `inverted` are unbindable
  (**G4**); the alert sound has never been shown to play (**G5**);
  `TimerButton` sets neither `css-name` nor the accessible role (**G6**);
  `Adwaita::AboutDialog` instead of `Adw.AboutWindow` (**G7**); no licence or
  contributing text (**G8**); no DOAP or Flatpak manifest (**G9**); no
  build-time validation (**G10**); the port has never been rendered or driven
  (**G11**).
- `.reports/translation-parity.md` — **T1**–**T3** (3): the two
  `msgctxt "a11y"` timer labels are set nowhere (**T1**); the eight shortcut
  titles sit behind a Ruby helper where no extractor can see them (**T2**);
  `Translate` and `Contribute` are port-invented msgids present in none of the
  42 catalogues (**T3**).
- `.reports/test-parity.md` — **TP1**–**TP2** (2): not one of the 145 cases
  has ever executed (the `gtk4`, `adwaita` and `gobject-introspection` gems are
  not installed in this tree); 8 of 18 units have no spec at all, including
  `Window`.
- `.reports/accountability-ensurance.md` — **A1**–**A7**: one comment to
  reword (`lib/chess_clock/signals.rb:13`) and six open gaps (**G1**, **G6**,
  **G8**, **G9**, **T1**, **TP2**) that are admitted in no source comment and
  in no `FINDINGS.md` row.

`FINDINGS.md` carries the long-form admissions. Nothing in it closes a gap.

## Blockers

Things that cannot be ported as upstream writes them, and why.

- **GSound has no ruby-gnome binding.** Upstream plays `dialog-warning` at
  volume 1 when a clock drops under 10% of its default (floor 10 s).
  `lib/chess_clock/alert_sound.rb` reaches GSound through
  `GObjectIntrospection::Loader`; namespace resolution, `Context#init` arity
  and `play_simple`'s `GHashTable` marshalling are all unverified. The routes
  are `canberra-gtk-play`, a shelled-out player, or silence with the mute
  action still honoured.
- **`Adwaita::Application` is unusable in the Ruby bindings.** The port uses
  `Gtk::Application`, which costs two conveniences libadwaita gives upstream
  for free: automatic `style.css` / `style-hc.css` loading from the resource
  base path, and automatic `help-overlay.ui` → `win.show-help-overlay` wiring.
  Both are hand-written here.
- **No GResource, so `Adw.AboutWindow.new_from_appdata` cannot read the
  metainfo.** Name, version, licence, developers, artists and translator
  credits are set explicitly in `about_dialog.rb` and will drift from
  `data/eu.fortysixandtwo.chessclock.metainfo.xml.in`.
- **`Adw.Breakpoint` setters carrying Pango attribute strings are
  GtkBuilder-only syntax.** Upstream's `0 -1 size 102400` on the three
  timerbutton labels at `min-width: 600px` has no setter equivalent; the
  font-size jump needs real `Pango::AttrList` work on breakpoint
  apply/unapply, or a CSS class swap instead.
- **`Gtk::Widget#add_tick_callback` coverage is uncertain in ruby-gnome.** The
  window drives the timers from per-frame ticks. A `GLib::Timeout` fallback
  keeps accuracy — the timers measure elapsed monotonic time, not frames — but
  not the per-frame smoothness.
- **`Gio::Settings` needs the gschema compiled and installed on the GSettings
  path.** Until the port ships and compiles
  `eu.fortysixandtwo.chessclock.gschema.xml`, settings run through a
  file-backed shim behind the same interface (**G2**).
- **Dynamic a11y updates may not be bound.** `update_property` with
  `Gtk::AccessibleProperty::LABEL` relabels each timer button as white and
  black swap sides. The static `.ui` labels are reachable; the live update may
  not be.
- **`Gtk::ShortcutsWindow` is deprecated as of GTK 4.18.** Still present, but
  whether the port uses it or `Adwaita::ShortcutsDialog` depends on the
  installed libadwaita.
- **Translation parity is out of reach in this step.** `po/` carries 42
  locales and `POTFILES.in` covers both the `.py` sources and all four `.ui`
  files; there is no gettext extraction path on the `ruby` branch yet.
