# Test parity — Chess Clock

| | |
|---|---|
| Upstream | `origin/main` @ `775f046` |
| Port | `ruby` @ `270aa8a` |
| Upstream tests | **0** |
| Ported | 0 |
| Gaps | 0 |
| Port tests (extra) | **0** |
| Test command | `rake spec` (RSpec, via kettle-dev) — **not run**, see below |

## Upstream has no test suite

Verified, not assumed:

```
test-census.sh <upstream tree>   → 0 rows
grep -rniE 'def test_|unittest|pytest|Test\.add_func|#\[test\]' <upstream tree> → no matches
```

There is no `test/` or `tests/` directory on `origin/main`, no `subdir('test')`
in the root `meson.build` (it has exactly three: `data`, `src`, `po`), no
`[[test]]`, no `pytest.ini` and no test target anywhere in the build. The
upstream tree is `src/` (7 Python files, 4 `.ui`, 2 `.css`), `data/`, `po/` and
packaging.

Parity is therefore **0/0 and is met trivially**.

## The port inherits no safety net

That is the finding, and it is not softened by the 0/0. The upstream suite is
normally the only surviving record of what the original authors found worth
pinning down; here there is no such record, so **every behaviour the port
reproduces is reproduced unchecked**. Nothing in this repository will tell
anyone if a port edit breaks it.

The behaviours that carry the most risk and have no test on either side:

| Behaviour | Where it lives in the port | Why it is the risky one |
|---|---|---|
| Bronstein refund is `min(inc − inc_timer.time, inc)` and the move timer resets per move | `bronstein_state_machine.rb:44` | three interacting timers; an off-by-one here gives a player free time every move and looks like a working clock |
| Simple delay holds the clock until `delay_timer` expires, and a mid-delay pause resumes with the remaining delay | `delay_state_machine.rb:44-57` | the `delay_timer.time.positive?` branch and the `@state == B_RUN` branch do different things and both set `running = false` |
| `expired` fires exactly once, on the crossing tick | `timer.rb:84` | depends on reading `previous` before the subtraction |
| alert threshold is `max(10% of default, 10 s)` | `timer.rb:93` | a two-minute game must alert at 10 s, not 12 |
| the clock face rounds *up* | `timer_button.rb:80` | a clock that truncates shows 0:00 for a whole second while time remains |
| `disconnect_all` removes every handler the machine installed, including both buttons' `clicked` | `state_machine.rb:107` | a leftover handler drives a dead machine from a live button, and the symptom is a clock that jumps |
| the seconds spin button carries into minutes on wrap | `time_control_entry.rb:103` | `> 30` borrows, else carries; inverted, the custom control silently sets the wrong game |
| idle inhibit is taken once per run streak and released on pause/start | `state_machine.rb:198` | a leaked cookie keeps the user's screen awake after the game ends |
| `Settings` round-trips all eight keys and keeps the unmaximized geometry | `settings.rb:69` | the only persistence the app has |

## The port's own suite does not load

`spec/` contains `README.md` and `spec_helper.rb` and **no spec files at all**.
Worse, `spec/spec_helper.rb:29` does

```ruby
require "chess/clock/rb"
```

and `lib/chess/clock/rb.rb` does not exist — the directory holds only
`version.rb`. Confirmed:

```
$ ruby -Ilib -e 'require "chess/clock/rb"'
cannot load such file -- chess/clock/rb (LoadError)
Did you mean?  chess/clock/rb/version
```

So the harness cannot even be loaded, let alone run. `rake spec` was **not
run** in this audit (the `gtk4` and `adwaita` gems are not installed in this
shell either, so no check that touches a widget could have run regardless) —
but the `LoadError` above is reproducible without them and is enough: there is
no suite, and the file that would bootstrap one is broken.

## Gaps

| # | Gap | Behaviour still owed |
|---|---|---|
| 1 | `lib/chess/clock/rb.rb` is missing, so `spec/spec_helper.rb` raises `LoadError` | `rake spec` loads and reports a count |
| 2 | `spec/` contains zero examples | The nine behaviours tabled above are each pinned by a named example, so a port edit that breaks the Bronstein refund or the up-rounding clock face fails the suite instead of shipping |
| 3 | No headless driver | The window, the two screens, the breakpoint and the six signals are driven per the `ruby-gtk-testing` skill, so "the port runs" becomes a claim someone can re-run |

Parity against upstream is 0/0. **Parity is not the finding; the absence of any
suite at all, on a port whose entire value is three interacting timer rule-sets,
is.** Rows 1–3 are the port's own debt, not upstream's, and they are gaps
exactly as the skill defines them.

## Extra

None. There is nothing to list.
