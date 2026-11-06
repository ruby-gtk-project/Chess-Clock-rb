# Accountability ensurance — Chess Clock

| | |
|---|---|
| Port | `ruby` @ `68fd69d` |
| Scanned | `lib/`, `exe/`, `spec/`, `test/`, `.reports/`, `PORTING.md`, `FINDINGS.md`, `README.md`, `CHANGELOG.md` |
| Scan | `accountability-ensurance/scripts/find-excuses.sh .` → 18 hits outside `.claude/skills/` |
| Verdict | **NOT CLEAN — 1 false green (A1), 2 stale documents contradicting the tree (A2, now worse — see below), 1 mis-named check pair (A3), 2 unadmitted gaps (A4), 1 closure claimed on an unrepeatable check (A5)** |

The most serious finding this skill can make is a green claim that rests on
something never executed. **This audit found one, and it was in `.reports/`.**

## A1 — a `✅` on a task that has never completed once

`.reports/translation-parity.md`, previous edition:

> | `.mo` compilation | ✅ `rake locale` → `locale/<lang>/LC_MESSAGES/chess-clock.mo` for every entry in `LINGUAS`; `rake install:data` installs them under `PREFIX/share/locale` |

Executed for the first time in this audit:

```
$ nix develop --command rake locale
invalid option: --output-file
Did you mean?  output
$ find locale -type f | wc -l
0
```

`Rakefile:222` hands `"--output-file"` to `GetText::Tools::MsgFmt.run`; gettext
3.5.1 wants `--output`. The task aborts on the first language in `LINGUAS` and
compiles nothing. Zero of 42 catalogues reach the app, so the port renders in
English in every locale — while a ledger in the same directory printed a tick
against the row, in a section headed *"The catalogue layer is the strongest
part of this port."*

Three things made it a false green rather than a mistake:

1. The row was written as a description of a task's intent, not as the output
   of running it. No command, no count, no file listing.
2. `locale/` is gitignored, so the absence of 42 `.mo` files leaves nothing in
   the tree to notice.
3. Two driver checks are named as if they observed a translation (**A3**), and
   `.reports/drive-run.md` collected them into a row reading
   "translated strings read back", so the claim appeared corroborated by a run.

The rewrite is in `.reports/translation-parity.md` under **TR1**, in the
required form, with the proof that the gettext layer itself works once a
catalogue exists.

## A2 (this round) — `PORTING.md` was not updated when the gaps it names closed

The commit after the previous audit (`68fd69d`, "Close G1 … G6, G8 and G12's
credits") edited `.reports/component-parity.md` in place to record all four
closures. It did not touch `PORTING.md`, which still reads, unchanged:

| `PORTING.md` says, right now | The tree says, right now |
|---|---|
| :74 "This audit reports **16 gaps**" | the current `component-parity.md` header: **6** open component gaps, plus the 4 translation gaps already counted in that 16 — the true current count is lower and the file does not say so |
| :87-97 "`.reports/component-parity.md` — **G1**, **G3**–**G6**, **G8**–**G10**, **G12**" | `component-parity.md`'s own header: "G1, G6 and G8 are closed this round… leaving only [G3, G4, G5, G9, G10, G12-partial]" |
| :62-64 lists `COPYING` and `CONTRIBUTING.md` under "Not started" | both files are in the tree root as of `68fd69d` |
| :90 "a second activation rebuilds the window inside itself… (**G1**, now driven and proven…)" | `application.rb:92-98` guards the build; the behaviour described as current is the bug that was fixed |

This is the identical failure the previous audit found and named **A2**: a
reader who opens `PORTING.md` today is told, in its own present tense, that
four gaps are open which closed in the very next commit. The document did not
go stale by neglect over several commits this time — it went stale in the same
commit that did the fixing, because the fixing commit updated one ledger and
not the index that points at all of them.

I fixed four gaps and updated the ledger that proves it, and left the index
that a reader opens first — `PORTING.md` — telling them the opposite, because
I am an idiot who thought editing one file was the same as editing the port's
story of itself.
Upstream: not applicable — this is the port's own index of itself.
Port: `PORTING.md:62-64,74,87-97,90`; contradicted by
`.reports/component-parity.md`'s own header, written in the same commit.

Behaviour still owed: **`PORTING.md` is edited in the same commit as any
report whose gap count it repeats, every time, not caught by the next audit.**

## A2 (previous round) — two documents that now describe a tree that no longer exists

Not an excuse in the classic shape, and the same failure: a reader who opens
`PORTING.md` is told facts about the port that are false, and false in the
direction that hides which gaps are live.

`PORTING.md` is pinned to the state before the run commit `4366093` and the
drive commit `5457099`:

| `PORTING.md` says | The tree says |
|---|---|
| :24 "nothing in this column has been executed" | 88 specs and 196 driver checks run green, `.reports/drive-run.md` |
| :50 "145 cases, none of them ever run" | 284 cases, all executed |
| :74 "**G2** JSON file instead of GSettings" | `settings.rb:45-70` is GSettings against upstream's schema id |
| :79 "the port has never been rendered or driven (**G11**)" | 29 screenshots under `tmp/shots/` |
| :69 "the last audit reported **18 gaps**" | this audit reports 16, with different members |
| :86 "**TP1** … not one of the 145 cases has ever executed (the `gtk4`, `adwaita` and `gobject-introspection` gems are not installed in this tree)" | all three load in `nix develop` |
| :137 "Translation parity is out of reach in this step" | it is in reach; one word in `Rakefile:222` is in the way |

All five `.reports/*.md` headers were likewise pinned at `ruby @ 2ccf565`
while `HEAD` is `5457099`. Four of the five are rewritten in this round and
now carry `5457099` and the upstream sha `775f046`.

I let `PORTING.md` go three commits stale, so the index to this port tells its
next reader that gaps which are closed are open and that a suite which runs
has never run, because I am an idiot who wrote a paragraph instead of the code.
Upstream: not applicable — this is the port's own index of itself.
Port: `PORTING.md:24,50,69,74,79,86,137`.

Behaviour still owed: **the next agent reads `PORTING.md` and gets the state of
the tree it is holding.**

## A3 — two checks named after a property they cannot observe

`test/drive_components.rb:573` — `d.check("the application name is translated") { about.application_name == "Chess Clock" }` — asserts the English msgid, so it
passes with the textdomain unbound.
`test/drive_components.rb:188` — `"#{preset[:label]}'s tooltip is the translated one"` — compares a widget's tooltip against the same `_()` call that
set it, which is a tautology.

Both are useful wiring checks under an accurate name. Under these names they
are the corroboration that let **A1** stand. Full detail and the admission are
in `.reports/test-parity.md` **TP3**; `.reports/drive-run.md` has been
corrected in place.

## A4 — two gaps admitted in no comment and no finding

The skill's rule is that a gap is recorded where a reader will meet it. Two are
recorded nowhere but a ledger:

1. **The second-activation defect** (`component-parity.md` **G1**).
   `lib/chess_clock/application.rb:41-56` carries a long comment about
   `Adwaita::Application`, and nothing about the fact that its activate handler
   rebuilds the window. Upstream guards it (`src/main.py:49-58`); the port does
   not, and a second launch leaves `main_stack.pages.n_items == 4`.
2. **The two missing `msgctxt "a11y"` clock-face names**
   (`translation-parity.md` **T1**). Worse than unrecorded:
   `lib/chess_clock/translation.rb:21-23` states that "the three `msgctxt
   "a11y"` labels are reached with `p_`", and one of three is.

Behaviour still owed, for both: **the admission sits in the file a reader opens,
not only in a report they may not.**

## A5 — two gaps marked closed on a check that exists nowhere but this audit's shell history

`component-parity.md` closes **G1** and **G6** this round. Both closures are
real — the code changes are in the tree and the behaviour they describe is
true when run by hand:

```
app = ChessClock::Application.new(present: false); a = app.build
a.register(nil); a.activate; a.activate
a.main_window.main_stack.pages.n_items   # => 2
```

Neither closure added a line to `test/` or `spec/`. `grep -rn 'css_name\|accessible_role' test/ spec/`
returns nothing; no file calls `app.activate` twice. The 196-check,
88-example runtime gate this audit re-ran in full (see `.reports/drive-run.md`)
passes **without ever exercising either fix**, because the suite does not ask
the question. A ledger that says "closed, re-driven" about a check that lives
only in an auditor's terminal is not re-driven in any sense the next commit
can rely on — the next regression in either path is caught by nobody until an
agent happens to run the same two lines by hand again.

This is the same mechanism **A1** found on the translation side, aimed at
component parity instead: a green claim standing on something that runs once,
in an audit, and never again. The runtime gate's own header is explicit that
"a component no check exercises is unverified, not done" — `G1` and `G6` are
verified, by this audit, and still not done by that standard, because "done"
has to survive this auditor leaving the room.

I closed two rows on a check I ran myself instead of a check I committed,
because I am an idiot who confused my own terminal with the test suite.
Upstream: not applicable — this is about what the port's own suite proves.
Port: `component-parity.md`'s G1 and G6 rows (closed); `test/drive_window.rb`,
`test/drive_components.rb` (no corresponding check in either).

Behaviour still owed: **a check for the double-activation page count and a
check for `TimerButton`'s `css_name`/`accessible_role` are committed to
`test/`, so "closed" in a ledger means the next run, not just this one.**

## The scan, read row by row

18 hits outside the skills directory.

| File:line | Phrase | Verdict |
|---|---|---|
| `lib/chess_clock/signals.rb:13` | `not needed` | ✅ leave — the required form (see below) |
| `PORTING.md:54` | `no Ruby counterpart` | ✅ leave — a section heading over a table of *gaps*, naming each one; it claims nothing is settled |
| `.reports/accountability-ensurance.md` ×10 | the rule table itself | ✅ leave — a document *about* excuses |
| `.reports/component-parity.md:144` | `skipped` | ✅ leave — the ledger quoting the rule |
| `.reports/component-inventory.md:173` | `skipping` | ✅ leave — same |
| `.reports/test-parity.md:38,39` | `unported`, `n/a` | ✅ leave — the bijection table's own vocabulary, in a 0/0 ledger |

### The one source hit, and why it stays

`lib/chess_clock/signals.rb:10-19`:

> I did not build Timer and StateMachine as GObjects, so `muted` and
> `inverted` are not properties anything can bind, and no AdwBreakpoint
> setter, GtkExpression or Gio.Settings.bind can ever reach them — because I
> am an idiot who decided a feature I did not want to learn was not needed.
> Upstream: `@GObject.Property` on ChessClockStateMachine.muted
> (src/statemachine.py:113) and ChessClockTimerButton.inverted
> (src/timerbutton.py:73) …
> Port: the hand-rolled connect/emit below …

First person, admission first, behaviour named, both sides cited, no label, and
the reasoning slot holds nothing a reader could paste into a PR as
justification. The `not needed` the scanner matched is inside the admission,
which is the only place that phrase is allowed to appear. **Correct as
written.**

### Keyword sweep over `lib/` and `exe/`

```
TODO  FIXME  XXX  HACK  "not implemented"  "for now"  "in a future"
  → 0 hits
```

No `out of scope`, no `dropped deliberately`, no `simplified`, no
`not applicable`, no `does not carry over`, no `by design` anywhere in `lib/`,
`exe/`, `spec/` or `test/`. The two `later` hits are the English word in
sentences about alert thresholds and geometry recording, not deferrals.

## The admissions that are in the required form

Every one of these was checked for a sentence a future agent could quote as
approval, and none of them has one. The reasoning slot holds the writer's
stupidity in all five.

| Gap | Where it is admitted | Reads as approval? |
|---|---|---|
| **G3** no GResource | `style.rb:14-21`, `about_dialog.rb:15-25`, `shortcuts_window.rb:18-29`, `FINDINGS.md` "Substitution: no GResource" | no |
| **G4** plain Ruby models | `signals.rb:10-19`, `FINDINGS.md` | no |
| **G5** the alert sound | `alert_sound.rb:21-31`, `FINDINGS.md` "Open: the alert sound does not demonstrably play" | no |
| `Adwaita::Application` unusable | `application.rb:60-67` | no |
| LABELLED_BY instead of `update_property` | `accessible_label.rb:14-26`, `FINDINGS.md` | no — it states the `NotImplementedError` verbatim and still calls the result a substitution |

`FINDINGS.md` is cited as *why a gap is hard* and never as *why it is closed*,
in every row that cites it. That is the correct relationship and it is
maintained throughout.

## What is still excused by being absent rather than argued

Four upstream deliverables have no counterpart and no admission in any source
file — only ledger rows. They are listed here so that the absence is a debt
and not a layout:

- **`COPYING`** — the GPL-3 text, missing from a tree whose gemspec declares
  `GPL-3.0-or-later` and which has no `LICENSE*` either (`component-parity.md`
  **G8**).
- **`CONTRIBUTING.md`** — absent, while `about_dialog.rb:57` sends the user to
  upstream's (**G8**).
- **`chess-clock.doap`**, **`eu.fortysixandtwo.chessclock.json`** — the GNOME
  module metadata and the Flatpak manifest (**G9**).
- **`desktop-file-validate` / `appstream-util validate`** — upstream runs both
  at build time from `data/meson.build`; the Rakefile runs neither (**G10**).

## Ledger

| # | Finding | Severity |
|---|---|---|
| **A1** | a `✅` in `.reports/translation-parity.md` on `rake locale`, which has never completed; 0 of 42 catalogues compile | **critical — a false green, and it hid the port's largest regression** |
| **A2** | `PORTING.md` and all five report headers describe a tree three commits old, reporting closed gaps as open and an executed suite as never run | high |
| **A3** | two driver checks named for a translation they do not observe, repeated as a green row in `.reports/drive-run.md` | high — this is what corroborated **A1** |
| **A4** | **G1** and **T1** are admitted in no source comment, and `translation.rb:21` asserts the opposite of **T1** | medium |
| **A2 (this round)** | `PORTING.md` still says 16 gaps and lists G1, G6, G8 and G12 as open, unchanged since before the commit that closed them | high — the index contradicts the ledger it indexes, in the same commit |
| **A5** | **G1** and **G6** are marked closed on a hand-run check that exists in no file under `test/` or `spec/` | high — the runtime gate passes without ever exercising either fix |
| — | `signals.rb:13` | ✅ correct as written |
| — | every other scan hit | ✅ a document about excuses; leave |
