# Component parity — Chess Clock

| | |
|---|---|
| Upstream | `origin/main` @ `775f046` |
| Port | `ruby` @ `9b4b7a4` |
| Units with parity | **16 / 18** |
| Verdict | **NOT AT PARITY — 2 open gaps: G3, G4.** G7 is a recorded substitution, not a gap. G1, G5, G6, G8, G9, G10, G12 are closed. |
| Runtime, re-run fresh for this audit | `nix develop --command xvfb-run -a ruby …`: **174 RSpec examples, 0 failures**; `test/drive_window.rb` 32/32, `test/drive_countdown.rb` 21/21, `test/drive_components.rb` 144/144 — **197/197 driver checks, 0 failed**, matching the stated runtime gate exactly, across 18 components |

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
| Behaviour | ❌ **G3** (no GResource), **G4** (`muted`/`inverted` unbindable). ⚠️ **G5 closed this round, with a residual**: the fork's `flake.nix` now carries the `gsound` typelib on `GI_TYPELIB_PATH`; `GObjectIntrospection::Loader.load("GSound", …)` resolves, `Context#init` succeeds and `play_simple` accepts the Ruby Hash — all three previously unverified. `test/drive_components.rb` asserts `GSound's typelib resolves and its context inits` as a real check, not a report. The event has still never been heard by a human: the shell has no PulseAudio/PipeWire/ALSA device, so `play_simple` raises `GLib::Error` ("Not available"), now rescued (previously unhandled — a real crash risk on any box with the typelib but no audio hardware) and falls back to the display bell exactly as a missing typelib would. **G1** (double-activation corruption) stays closed, now with a committed regression spec (`application_spec.rb`, closing the former **TP4**). |
| Text | ✅ **re-verified this round, and this reverses the previous audit's verdict**: `rake locale` compiles all 42 `.mo` files (`find locale -name '*.mo' \| wc -l` → 42, re-run fresh), `translation_spec.rb` and `pot_spec.rb` pass (5 examples), and a live German probe reads back `"Chess Clock" → "Schachuhr"`. **TR1, T1, T2, T3 are all closed** — see `.reports/translation-parity.md`. |
| Packaging / project | ✅ **G10 closed this round**: `flake.nix` now carries `desktop-file-utils` and `appstream` on the dev shell, and the `Rakefile` has a new `validate` task mirroring `data/meson.build`'s three checks. Re-run fresh: `rake validate` runs `desktop-file-validate` (1 hint, matching upstream's own multi-category-menu hint — not a port defect), `appstreamcli validate --no-net` (`✔ Validation was successful: infos: 3`, same three info-level notices upstream's own metainfo produces) and `glib-compile-schemas --strict --dry-run` (silent success). **G9** (DOAP + Flatpak manifest) stays **closed**: `chess-clock.doap` and `eu.fortysixandtwo.chessclock.json` are in the tree root, re-diffed byte-identical against `origin/main` this round. |

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
- **G5** — the GSound route is now real. Re-checked fresh this round:
  `nix develop --command bash -lc 'which desktop-file-validate appstreamcli'`
  resolve (packaged alongside `gsound` on the same `flake.nix` change), and
  `test/drive_components.rb`'s check 57 asserts `GSound's typelib resolves
  and its context inits` rather than reporting it. Two latent bugs this
  surfaced were fixed in the same commit: `play_simple`'s `GLib::Error` on a
  box with no sound server was previously unrescued (a live crash risk), and
  the GSound namespace was memoized per-`AlertSound`-instance, which raised
  `NameError` on the second `AlertSound` built in the process (every restart
  and every new game) and silently lost the real route after the first
  alert — now memoized on the class. **Residual, not re-opened**: no sound
  server exists in this Xvfb shell, so the event has still never been heard
  by a human; `play_via_gsound` is proven to reach libcanberra's backend and
  degrade cleanly, not to play audio a person hears.
- **G10** — `flake.nix` now puts `desktop-file-utils`, `appstream` and
  `gsound` on the dev shell's `PATH`/`GI_TYPELIB_PATH`, and the `Rakefile`
  gained a `validate` task. Re-run fresh this round: `rake validate` invokes
  `desktop-file-validate` (one hint about multi-category `Categories`,
  identical to the hint upstream's own `.desktop.in` produces — a pre-existing
  upstream characteristic, not introduced by the port), `appstreamcli
  validate --no-net` (`✔ Validation was successful: infos: 3`, the same
  three info-level notices — `developer-name-tag-deprecated`,
  `nonstandard-gnome-extension kudos`, `developer-info-missing` — that
  upstream's own metainfo would produce against this `appstream` version),
  and `glib-compile-schemas --strict --dry-run data` (silent success).

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
  in `signals.rb:10-19`. This is the one gap in `signals.rb` the house's
  hand-rolled mixin cannot close without becoming a real `GObject::Object`
  subclass, which the `ruby-gtk` skill's own notes on Ruby subclassing of
  GObject types flag as the harder, less-reliable path; not attempted this
  round, and not claimed closed anywhere in `lib/` or `.reports/`.

## What a check never exercises, named rather than claimed

1. **Real audio output** — `AlertSound` now reaches GSound's `play_simple`
   for real (closing **G5**'s dead-code concern), but no check, driver or
   spec asserts a sound was *heard*; the Xvfb shell has no PulseAudio,
   PipeWire or ALSA device, so the only assertion possible is that the
   `GLib::Error` fallback path is taken without crashing.
2. `Gtk::Accessible#update_property` — still raises `NotImplementedError` in
   this ruby-gnome version, so names go through LABELLED_BY and the LABEL
   property upstream sets directly is never asserted.
3. Synthetic key events — accelerators are asserted installed and actions
   activated; no key is pressed, because the display has no input device.
4. The high-contrast stylesheet swap — no portal on this display to drive
   `Adwaita::StyleManager#high-contrast`.
5. Non-English rendering under the drive scripts — `translation_spec.rb`
   reads a German string back via RSpec; none of the 197 driver checks runs
   in a non-English locale.

## Correction: the previously-committed reports were stale, not wrong for their time

`.reports/` as committed at `7fae0bd` ("Parity reports") accurately described
the tree at that commit, which still had **G5** and **G10** open. Two
commits landed afterward in the same session — `0302966` (installing the
GSound typelib and the validator binaries, closing **G5**/**G10**, and
fixing the two bugs GSound's real code path surfaced) and `9b4b7a4` (specs
for the remaining 7 units, closing the former **TP2**) — and neither commit
touched `.reports/` or `PORTING.md`. This audit opened the committed reports
first and found them describing gaps the tree had already closed two
commits earlier; re-running every check fresh (`rake validate`,
`test/drive_components.rb`, the full RSpec suite) rather than trusting the
committed prose is what surfaced this. See
`.reports/accountability-ensurance.md` for this as its own finding — it is
the same failure mode the previous round's **A6** named (a claim of
freshness that was not fresh), aimed at committed content this time rather
than an uncommitted draft.
