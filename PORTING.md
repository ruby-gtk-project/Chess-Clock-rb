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

Components implemented, and every one of them executed: 174 RSpec examples
(one spec file per `lib/chess_clock/*.rb` unit, 18/18) and 197 driver checks
run green in the fork's dev shell under `xvfb-run -a`. "Implemented and
driven" is not "at parity" — two component gaps are open below (**G3**,
**G4**); all translation gaps and all test-parity gaps are closed.

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
| `lib/chess_clock/settings.rb` | `data/eu.fortysixandtwo.chessclock.gschema.xml` (GSettings, file fallback) |
| `lib/chess_clock/translation.rb` | gettext textdomain binding |
| `exe/chess-clock` | `src/chess-clock.in` |
| `data/` (4 files) | `data/` — byte-identical to upstream |
| `po/` (42 locales + `LINGUAS`, `POTFILES.in`) | `po/` |
| `chess-clock.doap` | `chess-clock.doap` — byte-identical to upstream |
| `eu.fortysixandtwo.chessclock.json` | `eu.fortysixandtwo.chessclock.json` — byte-identical to upstream |

All 18 units now have a dedicated spec file (174 examples), closing **TP2**;
`test/drive_{window,countdown,components}.rb` add 197 more driver checks.
All 371 cases have been run, 0 failed — see `.reports/test-parity.md`.

## Not started

Upstream components with no Ruby counterpart at all.

| Upstream | Note |
|---|---|
| `src/chess-clock.gresource.xml` | no resource bundle on the port; CSS, the help overlay and the metainfo are retyped in Ruby instead (**G3**) |

`COPYING`, `CONTRIBUTING.md` (**G8**) and metadata validation (**G10**,
`rake validate` now runs `desktop-file-validate`, `appstreamcli validate
--no-net` and `glib-compile-schemas --strict --dry-run`) used to be rows in
this table; both are closed. `rake locale` and `rake pot` also exist and
work.

## Open gaps

Breakdown by report, as of this round's commit (`9b4b7a4`):

- `.reports/translation-parity.md` — **none open**. **TR1**, **T1**, **T2**,
  **T3** are all closed (see the report for detail).
- `.reports/component-parity.md` — **G3**, **G4** only (**G7** is a recorded
  substitution, not a gap): no GResource (**G3**); `Timer`/`StateMachine`
  are plain Ruby so `muted` and `inverted` are unbindable (**G4**). **G5**
  (alert sound) and **G10** (metadata validation) both close this round —
  `flake.nix` now carries the `gsound` typelib and the
  `desktop-file-validate`/`appstreamcli` binaries, `rake validate` runs all
  three checks for real, and `AlertSound` reaches a live GSound context
  (still never heard by a human — no sound server in this shell, see the
  report). **G1**, **G6**, **G8**, **G9**, **G12** stay closed.
- `.reports/test-parity.md` — **TP2** closes this round: all 18
  `lib/chess_clock/*.rb` units now have a dedicated spec file (previous
  gap: `about_dialog`, `accessible_label`, `alert_sound`, `primary_menu`,
  `shortcuts_window`, `style` and `window` had none). **TP1**, **TP3**,
  **TP4** stay closed. Test parity: **0/0 open gaps.**
- `.reports/accountability-ensurance.md` — **A7** (new): the committed
  `.reports/` and this file were two commits stale when this audit opened
  them — they still named **G5**, **G10** and **TP2** as open after the
  commits that closed each. Closed by this round's rewrite, re-verified
  against the tree rather than carried forward. **A1–A6** stay closed.

`FINDINGS.md` carries the long-form admissions. Nothing in it closes a gap.

## Blockers

Things that cannot be ported as upstream writes them, and why.

- **GSound has no ruby-gnome binding, but the GI route is now live.**
  Upstream plays `dialog-warning` at volume 1 when a clock drops under 10%
  of its default (floor 10 s). `lib/chess_clock/alert_sound.rb` reaches
  GSound through `GObjectIntrospection::Loader`; the dev shell now carries
  the `gsound` typelib, so namespace resolution, `Context#init` and
  `play_simple`'s `GHashTable` marshalling are all verified to work.
  No sound server exists in this Xvfb shell, so `play_simple` itself raises
  `GLib::Error` ("Not available"), rescued and falling back to
  `canberra-gtk-play`, a shelled-out player, or the display bell. The event
  has still never been heard by a human.
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
  timerbutton labels at `min-width: 600px` has no setter equivalent;
  `TimerButton`'s `apply`/`unapply` handlers build a real `Pango::AttrList`
  instead, driven on a 700px face and back. A correspondence, not a gap.
- **`Gtk::Widget#add_tick_callback` works, with one divergence.** Upstream
  installs both timers' callbacks in `ChessClockWindow.__init__`; here each
  `Timer` installs its own when it starts running and removes it by returning
  false. Driven to zero in `test/drive_countdown.rb`. Nothing on either side
  tests either shape.
- **`Gio::Settings` needs the gschema compiled and installed on the GSettings
  path.** `rake gschema` compiles it into `data/schemas` and `rake install:data`
  installs it under `PREFIX`; `Settings::SchemaStore` uses it whenever it is
  found and falls back to a JSON file otherwise. No longer a gap.
- **`Gtk::Accessible#update_property` cannot be called from Ruby.** It raises
  `NotImplementedError: TODO: in Ruby -> GIArgument(array/C)[interface(enum)](GtkAccessibleProperty)`
  for every argument shape, so `AccessibleLabel` names widgets through the
  LABELLED_BY relation instead. The names that route produces are driven; the
  LABEL property upstream sets is not asserted.
- **`Gtk::ShortcutsWindow` is deprecated as of GTK 4.18**, and its
  `action-name` → accelerator resolution happens in a `root` vfunc that has
  already run by the time Ruby holds the window. `ShortcutsWindow#resolve_accelerators`
  does that lookup by hand; without it the window lists six shortcuts and no
  key combinations.
- **`rake pot` only extracts what the gem's Ruby parser can read.** It covers
  every `.rb` file in `po/POTFILES.in`, including all eight `shortcut window`
  titles and all three `a11y` labels (`spec/chess_clock/pot_spec.rb`). The two
  non-Ruby files it also names — `data/eu.fortysixandtwo.chessclock.desktop.in`
  and the metainfo's `.xml.in` — need GNU `msgfmt --desktop`/`msgfmt --xml`
  to extract their own translatable fields (the `.desktop` `Keywords`, the
  metainfo's developer credit and screenshot caption), and that binary is
  not in this dev shell, so those few msgids are not regenerated.
