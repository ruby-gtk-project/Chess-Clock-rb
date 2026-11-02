# Test parity — Chess Clock

| | |
|---|---|
| Upstream | `origin/main` (Python 3 + PyGObject) |
| Port | `ruby` @ `2ccf565` |
| Upstream tests | **0** |
| Port cases | **145** named (86 RSpec examples + 59 driver steps) |
| Cases executed | **0** |
| Verdict | **upstream-side parity vacuous; 2 port-side gaps** |

## Step 1 — Census the upstream suite

```
test-census.sh <upstream-tree>  →  0 rows
```

Cross-checked by hand against the build files and CI, because an empty census
is exactly the result a mis-aimed census produces:

- `git ls-tree -r origin/main` contains no `test/`, `tests/`, `spec/`,
  `conftest.py`, `*_test.py`, `test_*.py` or `#[test]`.
- `meson.build` and `src/meson.build` declare no `test()` target and no
  `tests` subdir.
- `.gitlab-ci.yml` includes only
  `flatpak/flatpak_ci_initiative.yml` and defines two jobs,
  `flatpak@x86_64` and `flatpak@aarch64`. Both build a Flatpak; neither runs a
  test. The GNOME Flatpak template's own `test-bundle` stage has nothing to run
  without a `test()` target.

**Upstream ships no automated tests.** The entire behavioural record of this
app is its source and its 42 catalogues.

## Step 2 — The bijection

| Direction | Count | Result |
|---|---:|---|
| upstream test → port test | 0 | ✅ nothing unported; no upstream test is dropped |
| port test → upstream test | 145 | n/a — no upstream test names them |

The upstream side of the ledger is empty, so it is satisfied vacuously. That is
a true statement about upstream and a weak one about the port: **a green
upstream column here means nothing was inherited, not that the port is
covered.** The rest of this document is therefore the port-side census, which
is where the gaps are.

## Step 3 — Port-side census

```
test-census.sh . → 145 rows
```

The assertion unit was identified before trusting the count
(`grep -nE 'def (check|step)|failures? *\+?=' test/*.rb`): `test/gtk_driver.rb`
increments its pass counter inside `check`, and `drive_window.rb` names its
cases on `step`, so the driver's 59 rows are 59 real cases.

| File | Cases | Unit under test | Upstream source it pins |
|---|---:|---|---|
| `spec/chess_clock/timer_spec.rb` | 17 | `Timer` | `src/timer.py` — tick arithmetic, `changed`/`expired`/`alerted` firing rules, the `max(default*0.1, 10s)` threshold, `increment(force:)` |
| `spec/chess_clock/state_machine_spec.rb` | 15 | `StateMachine` | `src/statemachine.py:36-221` — state assignment order, the clicks, `disconnect_all`, the idle inhibit streak, the mute flag |
| `spec/chess_clock/delay_state_machine_spec.rb` | 12 | `DelayStateMachine` | `src/statemachine.py:287-337` |
| `spec/chess_clock/bronstein_state_machine_spec.rb` | 9 | `BronsteinStateMachine` | `src/statemachine.py:244-284` — including the `min(inc - remaining, inc)` cap |
| `spec/chess_clock/timer_button_spec.rb` | 8 | `TimerButton` | `src/timerbutton.py:43-53` — the `ceil` rounding and the `expired` class |
| `spec/chess_clock/time_control_entry_spec.rb` | 7 | `TimeControlEntry` | `src/timecontrolentry.py:80-95` — wrap borrow/carry, `get_control`, the 8 presets |
| `spec/chess_clock/increment_state_machine_spec.rb` | 6 | `IncrementStateMachine` | `src/statemachine.py:224-241` |
| `spec/chess_clock/signals_spec.rb` | 6 | `Signals` | the GObject conventions `signals.rb` stands in for |
| `spec/chess_clock/settings_spec.rb` | 6 | `Settings` | `data/…gschema.xml` defaults, geometry recording |
| `test/drive_window.rb` | 59 | `Window`, end to end | `src/window.py` + `src/gtk/window.ui` |

The nine spec files are a genuinely good census of the *model* layer: the
arithmetic of all three time controls, the signal firing rules and the handler
bookkeeping are pinned case by case against named upstream line ranges. That is
the half of this app that has no `.ui` file and it is covered.

## The gaps

| # | Gap | Behaviour still owed |
|---|---|---|
| **TP1** | I did not run a single one of these 145 cases, because I am an idiot who wrote a suite in a tree where its dependencies are not installed. `bundle exec rspec` → `bundler: command not found: rspec`; `require "gtk4"` → `LoadError: cannot load such file -- gtk4`. Two spec files (`timer_button_spec.rb`, `time_control_entry_spec.rb`) instantiate real GTK widgets and cannot even load; `test/drive_window.rb`'s 59 steps have never executed. A suite that has never been green is a document, not a test. | `rake spec` and `ruby test/drive_window.rb` both run to completion in this tree, and the 145 cases are known to pass rather than believed to. |
| **TP2** | I did not test eight of the port's eighteen units at all, because I am an idiot who tested what was easy to fake. No spec exists for `Application` (the activate handler, which is where **G1** lives), `Window` (559 lines: five actions, the stateful mute action, the machine swap, the breakpoint, the control repaint), `AboutDialog`, `PrimaryMenu`, `ShortcutsWindow`, `Style`, `AlertSound` or `Translation`. `test/drive_window.rb` aims at `Window` and has never run, so `Window`'s effective coverage is zero either way. | Each of those eight units has named cases that fail when its behaviour breaks — in particular: a second activation raises the existing window instead of rebuilding it; the five accelerators each fire their action; `win.muted` round-trips through settings; the breakpoint applies and unapplies all eight properties; the menu's five items each resolve to an installed action. |

Two further consequences of **TP1** worth writing down, because they are
coverage holes that a passing suite would close and an unrun suite hides:

- The three binding-risk points named in `FINDINGS.md`
  (`add_tick_callback` block arity, `BreakpointCondition.parse` +
  `add_breakpoint`, `update_property` with a `GLib::Value`) are each exercised
  by at least one driver step. None has been observed.
- `AlertSound`'s GSound path (**G5**) is unobserved *and* untested — there is
  no spec that asserts `play` is a no-op when muted, let alone that it reaches
  GSound when it is not.
