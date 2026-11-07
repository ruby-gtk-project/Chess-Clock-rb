# Component parity — Chess Clock

| | |
|---|---|
| Upstream | `origin/main` @ `775f046` |
| Port | `ruby` @ `28007cd` |
| Units with parity | **14 / 18** |
| Verdict | **NOT AT PARITY — 4 open gaps: G3, G4, G5, G10.** G7 is a recorded substitution, not a gap. G1, G6, G8, G9, G12 are closed. |
| Runtime, re-run fresh for this audit | `nix develop --command xvfb-run -a ruby …`: **99 RSpec examples, 0 failures**; `test/drive_window.rb` 32/32, `test/drive_countdown.rb` 21/21, `test/drive_components.rb` 143/143 — **196/196 driver checks, 0 failed**, matching the stated runtime gate exactly, across 18 components named in `.reports/drive-run.md` |

Four axes, all of which must hold for the same component: **count**, **style**
(CSS classes and their rules), **behaviour** (signals and actions), **text**
(translatable strings). The inventory is `.reports/component-identification.md`.

Nothing in `FINDINGS.md` or `PORTING.md` closes a row below on its own say-so;
a gap is only closed here when the code and, where claimed, a committed
check back it up.

## Summary by axis

| Axis | Result |
|---|---|
| Count | ✅ every upstream widget type present at the same true count once factories, repeaters and template-root double counts are read out (see `component-identification.md`) |
| Style | ⚠️ class *sets* identical (20 = 20), both stylesheets reproduced rule-for-rule; `css-name`/accessible-role are inherited rather than set explicitly, same result (**G6** closed) |
| Behaviour | ❌ **G3** (no GResource), **G4** (`muted`/`inverted` unbindable), **G5** (alert sound never heard, confirmed again this round — `which canberra-gtk-play` and the GSound typelib both fail in `nix develop`). **G1** (double-activation corruption) stays closed. |
| Text | ✅ **re-verified this round, and this reverses the previous audit's verdict**: `rake locale` compiles all 42 `.mo` files (`find locale -name '*.mo' \| wc -l` → 42, re-run fresh), `translation_spec.rb` and `pot_spec.rb` pass (5 examples), and a live German probe reads back `"Chess Clock" → "Schachuhr"`. **TR1, T1, T2, T3 are all closed** — see `.reports/translation-parity.md`. |
| Packaging / project | ❌ **G10** only (no `desktop-file-validate`/`appstream-util` equivalent, and neither binary exists in the dev shell to validate against). **G9** (DOAP + Flatpak manifest) is **closed**: `chess-clock.doap` and `eu.fortysixandtwo.chessclock.json` are in the tree root, re-diffed byte-identical against `origin/main` this round. |

## Closed gaps, re-verified this round

- **G1** — double-activation window corruption. `Application#on_activate`
  guards the one-time build with `@activated`. `application_spec.rb` now
  activates a built, registered app twice and asserts
  `main_stack.pages.n_items == 2`, so this is a committed check, not a
  hand-run one — the former **A5** finding against this closure is itself
  closed.
- **G6** — `css-name`/accessible role on the clock face. `TimerButton`
  subclasses `Gtk::Button` directly (`lib/chess_clock/timer_button.rb`), so
  both are inherited rather than set; `timer_button_spec.rb` exercises the
  widget live.
- **G8** — `COPYING` and `CONTRIBUTING.md` are in the tree root,
  byte-identical to upstream's.
- **G9** — `chess-clock.doap` and `eu.fortysixandtwo.chessclock.json` are in
  the tree root. Re-diffed this round: `diff <(git show origin/main:chess-clock.doap) chess-clock.doap` and the `.json` equivalent both produce no output.
  Neither file is installed or packaged by any Rake task — same status as
  `COPYING`/`CONTRIBUTING.md` under **G8**: present as project metadata, not
  wired into a build.
- **G12** — `about_dialog.rb`'s developer list matches `main.py:58-61`
  including the stray ZWJ+VS16 pair after "Clara Hobbs"; the release-notes
  version is upstream's literal `"0.6.0"`. The `version` *property* the port
  sets separately (`"0.6.2"`) is a documented divergence, not owed work — it
  names the port's own release, not upstream's, and upstream's dialog has no
  such property at all.

## Open gaps, detail

- **G3 — no GResource.** `find . -iname '*.gresource*'` returns nothing.
  `Style#load` installs both stylesheets on the display by hand
  (`lib/chess_clock/style.rb`), and the shortcuts window is wired to
  `win.show-help-overlay` by hand rather than by `AdwApplication` finding
  `help-overlay.ui` on a resource path. The rendered result matches upstream,
  but every edit to CSS or the shortcuts window is now an edit to Ruby
  source with nothing on the upstream side to check it against. Admitted in
  `style.rb`, `about_dialog.rb`, `shortcuts_window.rb`.
- **G4 — `muted`/`inverted` are unbindable.** `Timer` and `StateMachine`
  (confirmed by reading `lib/chess_clock/timer.rb`,
  `lib/chess_clock/state_machine.rb`) dispatch through the hand-rolled
  `Signals` mixin rather than subclassing `GObject::Object`. Upstream's
  `ChessClockTimer.muted` and the equivalent on `ChessClockStateMachine`/
  `ChessClockTimerButton.inverted` are real `GObject.Property`s that
  `Gio::Settings#bind`, an `AdwBreakpoint` setter or a `GtkExpression` can
  target directly; the port's are plain Ruby attribute writers, reached only
  through explicit method calls on both ends of every binding site. Admitted
  in `signals.rb:10-19`.
- **G5 — the alert sound has never been heard.** `ruby-gnome` has no GSound
  binding. Re-checked fresh this round: `which canberra-gtk-play` fails, and
  `GObjectIntrospection::Loader.load("GSound", …)` raises `TypelibNotFound`
  in the fork's `nix develop` shell. `AlertSound#play`'s GSound-reaching
  branch is therefore dead code on every machine this port has run on; only
  its `muted` short-circuit and its own fallback are proven to execute.
  `test/drive_components.rb`'s alert check reports rather than asserts the
  GSound route (see `.reports/accountability-ensurance.md`). Admitted in
  `alert_sound.rb:21-31`, `FINDINGS.md`.
- **G10 — no metadata validation.** `data/meson.build` runs
  `desktop-file-validate` and `appstream-util validate` on the desktop entry
  and metainfo at build time; the `Rakefile` has `locale`, `pot`, `gschema`
  and `install:data` and no validation task (`grep -n
  'desktop-file-validate\|appstream-util\|appstreamcli' Rakefile` →
  nothing), and none of the three binaries is installed in the dev shell to
  validate against even if a task called them (`which` fails on all three,
  re-checked this round).

## What a check never exercises, named rather than claimed

1. **GSound** (**G5**) — no typelib in the dev shell, ever.
2. `Gtk::Accessible#update_property` — still raises `NotImplementedError` in
   this ruby-gnome version, so names go through LABELLED_BY and the LABEL
   property upstream sets directly is never asserted.
3. Synthetic key events — accelerators are asserted installed and actions
   activated; no key is pressed, because the display has no input device.
4. The high-contrast stylesheet swap — no portal on this display to drive
   `Adwaita::StyleManager#high-contrast`.
5. Non-English rendering under the drive scripts — `translation_spec.rb`
   reads a German string back via RSpec; none of the 196 driver checks runs
   in a non-English locale.

## Correction to a stale working-tree draft found at the start of this audit

Before this round's reports were written, the working tree carried an
uncommitted, never-finished edit of this file (and of
`component-identification.md`) that still listed **G9** as open — "confirmed
again: no `*.doap`, no `*.json` Flatpak manifest anywhere in the tree" —
despite `chess-clock.doap` and `eu.fortysixandtwo.chessclock.json` already
being in the tree root, added by the committed `28007cd` ("Add DOAP and
Flatpak manifest, closing G9"). `find . -iname '*.doap'` and `-iname
'*chessclock*.json'` both return a hit; the draft's claim was checked against
neither. That draft never reached `.reports/` as committed content, so it
never shipped as a false claim, but it would have if this round had trusted
it instead of re-running `find` and `diff` directly. See
`.reports/accountability-ensurance.md` for this as its own finding.
