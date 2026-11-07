# Test parity — Chess Clock

| | |
|---|---|
| Upstream | `origin/main` @ `775f046` |
| Port | `ruby` @ `9b4b7a4` |
| Upstream tests | **0** |
| Ported | **0** |
| Gaps (parity) | **0 — met trivially** |
| Port cases | **174 RSpec examples** + 197 driver checks |
| Cases executed, re-run fresh this round | **371, all of them, 0 failures** |
| Test commands | `ruby -e 'require "rspec/core"; exit RSpec::Core::Runner.run(["--format","progress","--require","spec_helper","spec"])'` and `ruby test/drive_{window,countdown,components}.rb`, each under `nix develop --command xvfb-run -a` |
| Verdict | **parity 0/0, met trivially — TP1, TP2, TP3, TP4 all closed** |

## Step 1 — census the upstream suite

```
test-census.sh <upstream-tree>  →  0 rows
```

Cross-checked by hand: `git ls-tree -r --name-only origin/main` has no
`test/`, `tests/`, `spec/`, `conftest.py`, `*_test.py` or `test_*.py`.
`meson.build` and `src/meson.build` declare no `test()` target.
`.gitlab-ci.yml` only builds Flatpaks for two architectures; neither stage
runs a test. **Upstream ships no automated tests.** Parity is 0/0 and is met
trivially — the port inherits no upstream safety net, and every case below
was written for the port, pinning no property upstream itself ever pinned.

## Step 2 — the bijection

| Direction | Count | Result |
|---|---:|---|
| upstream test → port test | 0 | ✅ nothing unported |
| port test → upstream test | 371 | n/a by definition — all 371 are `## Extra` |

## Step 3 — the suite actually runs, re-verified fresh this round

```
$ nix develop --command xvfb-run -a ruby -e 'require "rspec/core"; …'
174 examples, 0 failures

$ nix develop --command xvfb-run -a ruby test/drive_window.rb
32 of 32 checks passed     DRIVE OK
$ nix develop --command xvfb-run -a ruby test/drive_countdown.rb
21 of 21 checks passed     DRIVE OK
$ nix develop --command xvfb-run -a ruby test/drive_components.rb
144 of 144 checks passed   DRIVE OK
```

197 driver checks + 174 RSpec examples = 371, 0 failed, 18 components —
matching the round's stated runtime gate exactly (197 checks, 0 failed, 18
components). `GtkDriver::Session#check` (`test/gtk_driver.rb`) counts every
call, fails on a falsey block and on a raised `StandardError`, and exits
non-zero on any failure; a green run here is a real green run.

## `## Extra` — spec files, by unit (18 files, 174 examples)

Every one of the 18 `lib/chess_clock/*.rb` units now has a dedicated spec
file: `about_dialog_spec.rb`, `accessible_label_spec.rb`,
`alert_sound_spec.rb`, `application_spec.rb`,
`bronstein_state_machine_spec.rb`, `delay_state_machine_spec.rb`,
`increment_state_machine_spec.rb`, `primary_menu_spec.rb`, `settings_spec.rb`,
`shortcuts_window_spec.rb`, `signals_spec.rb`, `state_machine_spec.rb`,
`style_spec.rb`, `time_control_entry_spec.rb`, `timer_button_spec.rb`,
`timer_spec.rb`, `translation_spec.rb`, `window_spec.rb`, plus `pot_spec.rb`
(extraction path, not a `lib/` unit).

`about_dialog_spec.rb`, `accessible_label_spec.rb`, `alert_sound_spec.rb`,
`primary_menu_spec.rb`, `shortcuts_window_spec.rb`, `style_spec.rb` and
`window_spec.rb` are new this round (commit `9b4b7a4`) — these are the seven
units the previous audit found reached only by the drive scripts. This
closes **TP2**. `window_spec.rb` builds through a real
`ChessClock::Application` with an isolated per-example `Settings` file
(the default `FileStore` path is shared process-wide and would otherwise
leak `control-method`/`muted` between examples) and covers the two-page
stack, the setup↔timer transition, machine-class selection, the mute
action's activate/change-state roundtrip, `on_pause`'s icon/sensitivity,
window-control repainting on `awbb`/`abbw`, and the narrow breakpoint's four
checks — the largest file in the port (564 lines) had no spec at all before
this round.

## TP1 — closed

The suite had never been executed as of the oldest round's audit. Re-run
fresh every round since, including this one: 371/371 pass.

## TP2 — closed this round

The previous audit found 11 of 18 `lib/chess_clock/*.rb` units specced, with
`about_dialog`, `accessible_label`, `alert_sound`, `primary_menu`,
`shortcuts_window`, `style` and `window` reached only by the three drive
scripts. Re-checked fresh this round:

```
$ ls lib/chess_clock/*.rb | xargs -n1 basename | sed 's/\.rb$//' | sort > /tmp/units
$ ls spec/chess_clock/*_spec.rb | xargs -n1 basename | sed 's/_spec\.rb$//' | sort > /tmp/specced
$ comm -23 /tmp/units /tmp/specced
```

produces no output — all 18 units now have a dedicated spec file (commit
`9b4b7a4`, landed after the previous round's reports and not yet reflected
in them when this audit opened them; see `accountability-ensurance.md`).
`window_spec.rb` in particular covers the file that was the largest in the
port (564 lines) and previously had no spec at all. **Closed, and verified
by a bijection, not by reading the commit message.**

## TP3 — closed

The previous audit found two driver checks named for a property they did
not observe (`test/drive_components.rb:573`'s "the application name is
translated", which asserted the untranslated English msgid; and a tooltip
tautology at line 188). Both are renamed to describe wiring rather than
translation, and `translation_spec.rb` is now the real locale-switching
check (`LANG=de_DE.UTF-8`, reads back `"Schachuhr"`). Re-read this round;
still renamed, still accurate.

## TP4 — closed

`application_spec.rb` builds, registers and activates an app twice and
asserts `main_stack.pages.n_items == 2` — the double-activation defect
(component-parity **G1**) now has a committed regression check, not only a
hand-run terminal session. This also closes the previous audit's **A5**
finding against **G1**'s closure.

## Ledger

| # | Gap | Status |
|---|---|---|
| **TP1** | suite never executed | closed — 371/371, re-run fresh this round |
| **TP2** | 7/18 units reached only by drive scripts, not `spec/` | closed — bijection re-run this round, no unspecced unit remains |
| **TP3** | two checks named for a property they do not observe | closed — renamed, real check added |
| **TP4** | double-activation closure had no committed check | closed — `application_spec.rb` |
