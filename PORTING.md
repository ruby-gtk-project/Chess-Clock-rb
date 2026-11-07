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

Components implemented, and every one of them executed: 99 RSpec examples and
196 driver checks run green in the fork's dev shell under `xvfb-run -a`
(`.reports/drive-run.md`). "Implemented and driven" is not "at parity" — five
component gaps are open below; all four translation gaps from the previous
audit (**TR1**, **T1**, **T2**, **T3**) are closed this round.

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

Specs exist for 11 of the 18 units (99 examples, after this round added
`application_spec.rb`, `translation_spec.rb` and `pot_spec.rb`); the other
seven are reached only by the three drive scripts (196 checks). All 295 cases
have been run — see **TP2** for the shape gap that leaves.

## Not started

Upstream components with no Ruby counterpart at all.

| Upstream | Note |
|---|---|
| `src/chess-clock.gresource.xml` | no resource bundle on the port; CSS, the help overlay and the metainfo are retyped in Ruby instead (**G3**) |
| `COPYING` | GPL-3 licence text, absent from a GPL-3 derivative (**G8**) |
| `CONTRIBUTING.md` | absent; the About window's Contribute link points at upstream's (**G8**) |
| `chess-clock.doap` | GNOME project metadata (**G9**) |
| `eu.fortysixandtwo.chessclock.json` | Flatpak manifest (**G9**) |
| `data/meson.build` validation | `desktop-file-validate`, `appstream-util validate` — no Rake equivalent, and neither binary is in the dev shell to validate against (**G10**) |
| `src/meson.build`, `meson.build` | build system replaced by `Rakefile` + gemspec; compile/install only, no validation |

`rake locale` and `rake pot` now exist and work — see **Closed this round**
below; they used to be rows in this table.

## Open gaps

Breakdown by report, as of this round's commit:

- `.reports/translation-parity.md` — **none open**. All four of the previous
  round's gaps are closed this round: **TR1** (`Rakefile`'s `locale` task
  passed `--output-file` to a `MsgFmt` that wants `--output`; fixed, and all
  42 `.mo` files now compile, verified by `spec/chess_clock/translation_spec.rb`
  reading `"Chess Clock"` back as `"Schachuhr"` under `de`); **T1** (the two
  `msgctxt "a11y"` clock-face names are now built at `TimerButton`
  construction via `p_("a11y", …)`, matching window.ui's static initial
  label, with `translation.rb:21`'s comment corrected); **T2** (the eight
  `msgctxt "shortcut window"` titles are now literal `p_` calls the
  extractor can see, a `rake pot` task exists, and
  `spec/chess_clock/pot_spec.rb` asserts all eight plus the three `a11y`
  labels come back out of a real extraction over `po/POTFILES.in`); **T3**
  (the invented `Translate`/`Contribute` links are removed — libadwaita's own
  `new_from_appdata` never reads those two `<url>` types at all, so upstream's
  dialog never showed them either).
- `.reports/component-parity.md` — **G3**–**G5**, **G9**, **G10** (5; **G7**
  is a recorded substitution, not a gap): no GResource (**G3**);
  `Timer`/`StateMachine` are plain Ruby so `muted` and `inverted` are
  unbindable (**G4**); the alert sound has never been heard, no GSound
  typelib in this shell (**G5**); no DOAP or Flatpak manifest (**G9**); no
  metadata validation, and neither `desktop-file-validate` nor
  `appstream-util`/`appstreamcli` is in this dev shell to validate against
  (**G10**). **G1**, **G6**, **G8** and **G12**'s credits half are closed,
  now with checks that exercise them (`application_spec.rb` for G1,
  `timer_button_spec.rb` for G6); **G12**'s release-notes-version half is
  closed too — `about_dialog.rb`'s `RELEASE_NOTES_VERSION` now matches
  `main.py`'s literal `"0.6.0"` exactly rather than the metainfo's newest
  release. **G7** — `Adwaita::AboutDialog` for the deprecated
  `Adw.AboutWindow` — is a recorded substitution and is not counted.
- `.reports/test-parity.md` — **TP2** (partial: `application`, `translation`
  and the pot-extraction path now have specs; `about_dialog`, `primary_menu`,
  `shortcuts_window`, `style`, `accessible_label` and `alert_sound` still do
  not); **TP3** (closed — the two tautological checks in
  `test/drive_components.rb` are renamed to describe wiring, and
  `translation_spec.rb` is the real locale-switching check); **TP4** (closed
  — `application_spec.rb` activates twice and asserts
  `main_stack.pages.n_items == 2`). **TP1** is closed.
- `.reports/accountability-ensurance.md` — **A2**, **A5** (closed by this
  edit and by the two specs above landing in the same commit as the reports
  they corroborate).

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
- **`rake pot` only extracts what the gem's Ruby parser can read.** It covers
  every `.rb` file in `po/POTFILES.in`, including all eight `shortcut window`
  titles and all three `a11y` labels (`spec/chess_clock/pot_spec.rb`). The two
  non-Ruby files it also names — `data/eu.fortysixandtwo.chessclock.desktop.in`
  and the metainfo's `.xml.in` — need GNU `msgfmt --desktop`/`msgfmt --xml`
  to extract their own translatable fields (the `.desktop` `Keywords`, the
  metainfo's developer credit and screenshot caption), and that binary is
  not in this dev shell, so those few msgids are not regenerated.
