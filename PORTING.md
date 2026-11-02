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

Components implemented, and every one of them executed: 88 RSpec examples and
196 driver checks run green in the fork's dev shell under `xvfb-run -a`
(`.reports/drive-run.md`). "Implemented and driven" is not "at parity" — nine
component gaps and four translation gaps are open below.

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

Specs exist for 9 of the 18 units (88 examples); the other nine are reached
only by the three drive scripts (196 checks). All 284 cases have been run — see
**TP2** for the shape gap that leaves.

## Not started

Upstream components with no Ruby counterpart at all.

| Upstream | Note |
|---|---|
| `src/chess-clock.gresource.xml` | no resource bundle on the port; CSS, the help overlay and the metainfo are retyped in Ruby instead (**G3**) |
| `COPYING` | GPL-3 licence text, absent from a GPL-3 derivative (**G8**) |
| `CONTRIBUTING.md` | absent; the About window's Contribute link points at upstream's (**G8**) |
| `chess-clock.doap` | GNOME project metadata (**G9**) |
| `eu.fortysixandtwo.chessclock.json` | Flatpak manifest (**G9**) |
| `data/meson.build` validation | `desktop-file-validate`, `appstream-util validate` — no Rake equivalent (**G10**) |
| `po/meson.build` `.pot` regeneration | no gettext extraction path on `ruby` (**G10**, **T2**) |
| `po/meson.build` `msgfmt` | `rake locale` exists and **aborts on the first language**, so 0 of 42 `.mo` files are produced (**TR1**) |
| `src/meson.build`, `meson.build` | build system replaced by `Rakefile` + gemspec; compile/install only, no validation |

## Open gaps

This audit reports **16 gaps** and **clean = false**, against `origin/main` @
`775f046`. Breakdown by report:

- `.reports/translation-parity.md` — **TR1**, **T1**, **T2**, **T3** (4).
  **TR1 is the worst gap in the port and was previously reported as a tick:**
  `Rakefile:222` passes `--output-file` to a `MsgFmt` that wants `--output`, so
  `rake locale` aborts on `az` and compiles no catalogue at all. The app is
  English-only in every locale. One word closes it. Also: the two
  `msgctxt "a11y"` clock-face names are set nowhere (**T1**, and
  `translation.rb:21` claims otherwise); the eight shortcut titles sit behind a
  Ruby helper where no extractor can see them and there is no `.pot` target
  (**T2**); `Translate` and `Contribute` are port-invented msgids in none of
  the 42 catalogues (**T3**).
- `.reports/component-parity.md` — **G1**, **G3**–**G6**, **G8**–**G10**,
  **G12** (9; **G7** is a recorded substitution, not a gap): a second
  activation rebuilds the window inside itself, leaving
  `main_stack.pages.n_items == 4` and four GTK criticals (**G1**, now driven
  and proven, reachable through `DBusActivatable=true`); no GResource
  (**G3**); `Timer`/`StateMachine` are plain Ruby so `muted` and `inverted`
  are unbindable (**G4**); the alert sound has never been heard (**G5**);
  `TimerButton` sets neither `css-name` nor the accessible role (**G6**); no
  licence or contributing text (**G8**); no DOAP or Flatpak manifest
  (**G9**); no metadata validation (**G10**); the About window shows a
  different release's notes and retyped credits (**G12**).
  **G7** — `Adwaita::AboutDialog` for the deprecated `Adw.AboutWindow` — is a
  recorded substitution and is not counted.
- `.reports/test-parity.md` — parity is **0/0 and met trivially**: upstream
  ships no tests, so the port inherits no safety net. Three port-side gaps:
  9 of 18 units have no spec (**TP2**); two driver checks are named for a
  translation they do not observe (**TP3**); the second-activation path is
  tested by nothing (**TP4**). **TP1** — "never executed" — is closed.
- `.reports/accountability-ensurance.md` — **A1**–**A4**: one false green
  (**A1**, the `rake locale` tick); this file and all five report headers
  three commits stale (**A2**); two mis-named checks that corroborated **A1**
  (**A3**); **G1** and **T1** admitted in no source comment (**A4**).

Closed since the previous audit: **G2** (GSettings now backs `Settings`),
**G11** / **TP1** (the port has been built, opened, screenshotted and driven).

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
- **There is no gettext *extraction* path on `ruby`.** `POTFILES.in` is
  retargeted at `lib/` and `data/`, and nothing regenerates a `.pot` from it,
  so the eight shortcut titles hidden behind `ShortcutsWindow.title` are
  unextractable and unnoticed (**T2**). *Lookup* is not blocked: with a
  catalogue present, every one of the 48 ported keys — including all eight
  `shortcut window` contexts — resolves, verified in German. The only thing
  stopping the 42 languages from working is **TR1**.
