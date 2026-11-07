# Test parity — Chess Clock

| | |
|---|---|
| Upstream | `origin/main` @ `775f046` |
| Port | `ruby` @ `28007cd` |
| Upstream tests | **0** |
| Ported | **0** |
| Gaps (parity) | **0 — met trivially** |
| Port cases | **99 RSpec examples** + 196 driver checks |
| Cases executed, re-run fresh this round | **295, all of them, 0 failures** |
| Test commands | `ruby -e 'require "rspec/core"; exit RSpec::Core::Runner.run(["--format","progress","--require","spec_helper","spec"])'` and `ruby test/drive_{window,countdown,components}.rb`, each under `nix develop --command xvfb-run -a` |
| Verdict | **parity 0/0, met trivially — and 1 port-side gap (TP2); TP1, TP3, TP4 are closed** |

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
| port test → upstream test | 295 | n/a by definition — all 295 are `## Extra` |

## Step 3 — the suite actually runs, re-verified fresh this round

```
$ nix develop --command xvfb-run -a ruby -e 'require "rspec/core"; …'
99 examples, 0 failures

$ nix develop --command xvfb-run -a ruby test/drive_window.rb
32 of 32 checks passed     DRIVE OK
$ nix develop --command xvfb-run -a ruby test/drive_countdown.rb
21 of 21 checks passed     DRIVE OK
$ nix develop --command xvfb-run -a ruby test/drive_components.rb
143 of 143 checks passed   DRIVE OK
```

196 driver checks + 99 RSpec examples = 295, 0 failed, 18 components named in
`.reports/drive-run.md` — matching the round's stated runtime gate exactly.
`GtkDriver::Session#check` (`test/gtk_driver.rb`) counts every call, fails on
a falsey block and on a raised `StandardError`, and exits non-zero on any
failure; a green run here is a real green run.

## `## Extra` — spec files, by unit (12 files, 99 examples)

`application_spec.rb`, `bronstein_state_machine_spec.rb`,
`delay_state_machine_spec.rb`, `increment_state_machine_spec.rb`,
`pot_spec.rb`, `settings_spec.rb`, `signals_spec.rb`,
`state_machine_spec.rb`, `time_control_entry_spec.rb`,
`timer_button_spec.rb`, `timer_spec.rb`, `translation_spec.rb`.

`application_spec.rb`, `translation_spec.rb` and `pot_spec.rb` are new since
the previous audit (which counted 88 examples across 9 files); they are what
closes **TP4** (a committed check for double-activation) and give **TR1**/
**T1**/**T2**'s closures in `translation-parity.md` a check in `spec/`
rather than only a hand-run probe.

## TP1 — closed

The suite had never been executed as of the oldest round's audit. Re-run
fresh every round since, including this one: 295/295 pass.

## TP2 — partial, still open

11 of the 18 `lib/chess_clock/*.rb` units have a dedicated spec file (listed
above, counting `translation.rb` and the pot-extraction path). The other 7
are reached only by the three drive scripts, never by a committed RSpec
example:

```
$ ls lib/chess_clock/ | sed 's/\.rb$//'  minus the 11 with specs above
about_dialog
accessible_label
alert_sound
primary_menu
shortcuts_window
style
window
```

This is unchanged from the previous audit except that `application` moved
from this list to the specced list. `window.rb` is the largest file in the
port by a wide margin and has no spec at all — it is driven, but only by
the three scripts, none of which is run on every commit the way `rspec`
would be in CI. **Open, not excused**: nothing in `lib/` or `.reports/`
claims these 7 are specced; `PORTING.md` names the gap accurately.

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
| **TP1** | suite never executed | closed — 295/295, re-run fresh this round |
| **TP2** | 7/18 units reached only by drive scripts, not `spec/` | **open** |
| **TP3** | two checks named for a property they do not observe | closed — renamed, real check added |
| **TP4** | double-activation closure had no committed check | closed — `application_spec.rb` |
