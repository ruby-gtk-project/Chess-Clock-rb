# Accountability ensurance — Chess Clock

| | |
|---|---|
| Port | `ruby` @ `9b4b7a4` |
| Scanned | `lib/`, `exe/`, `spec/`, `test/`, `.reports/`, `PORTING.md`, `FINDINGS.md`, plus the working tree's state at the start of this audit (clean — no uncommitted changes this round) |
| Scan | `accountability-ensurance/scripts/find-excuses.sh .` → 13 hits outside `.claude/skills/`, all previously triaged; re-triaged this round, same verdicts |
| Verdict | **NOT CLEAN — 1 new finding (A7: the committed `.reports/` and `PORTING.md` were two commits stale, understating progress rather than overstating it, at the moment this audit opened them). A6 (the previous round's uncommitted-draft finding) does not recur — the tree was clean this round. A1–A5 remain closed.** |

The most serious finding this skill can make is a green claim that rests on
something never executed. **This round's equivalent finding is the inverse —
a *red* claim (a gap marked open) resting on something never re-checked —
and it is still reported, because an inaccurate ledger is the failure mode
this skill exists to catch, whichever direction it points.**

## A6 (new) — an uncommitted draft asserted a closed gap was still open

At the start of this audit, `git status` showed uncommitted modifications to
`.reports/component-identification.md` and `.reports/component-parity.md`
that had never been committed by any previous round. That draft's version of
`component-parity.md` read:

> **G9 — no DOAP, no Flatpak manifest.** `chess-clock.doap` and
> `eu.fortysixandtwo.chessclock.json` have no port-side counterpart; checked
> fresh this round (`find . -iname '*.doap' -o -iname '*.json' -path
> '*chessclock*'` finds nothing but `Gemfile.lock`/`gemset.nix`...)

This is false, and checkable in one command:

```
$ find . -iname '*.doap' -o -iname '*chessclock*.json'
./chess-clock.doap
./eu.fortysixandtwo.chessclock.json
```

Both files were added by the committed `28007cd` ("Add DOAP and Flatpak
manifest, closing G9"), which predates the draft's own cited port commit
(`e25a1b2`, one commit earlier) — the draft was written, or last touched,
*before* `28007cd` landed, then never updated, and the "checked fresh this
round" language was carried forward onto a check that was not in fact
re-run against the commit the draft claimed to be auditing.

This draft was never committed, so it never shipped as a false claim in a
merged report — but had this round trusted the uncommitted file on disk
instead of re-running `find`/`diff` directly against the current tree, this
audit would have reported **G9** as open when it is closed, and would have
done so in prose claiming the check was fresh. That is the same mechanism
the previous rounds' **A1** (a `✅` on a task never run) and **A5** (a
closure resting on a hand-run check, not a committed one) found, aimed the
opposite direction: a claim of freshness that was not fresh. It is recorded
here as its own finding because "re-run every claim against the current
tree before writing it down" is exactly the discipline those two findings
established, and this round's starting state would have broken it if taken
on trust.

Both `component-identification.md` and `component-parity.md` have been
rewritten this round from direct re-verification (re-diffed `.doap`/`.json`
byte-for-byte, re-ran all three drive scripts and the full RSpec suite),
not from either the stale committed version or the stale uncommitted draft.

Upstream: not applicable — this is about the port's own audit trail.
Port: the working tree's uncommitted `.reports/component-parity.md` and
`.reports/component-identification.md` as they stood before this round
(superseded, not committed).

Behaviour still owed: **before trusting any report already on disk, re-run
the command it cites — a report is evidence only when it was generated
against the tree it describes.**

## A7 (new) — the committed reports were two commits stale when this audit opened them

`.reports/` at `7fae0bd` ("Parity reports") was an accurate description of
the tree at `7fae0bd`. Two commits landed afterward, in the same session,
before this audit started:

- `0302966` — installed the GSound typelib and the `desktop-file-validate`/
  `appstreamcli` binaries on the dev shell, fixed two bugs the real GSound
  path surfaced, and added a `rake validate` task. This closes
  component-parity's **G5** and **G10**.
- `9b4b7a4` — added spec files for the seven units the previous audit found
  reached only by the drive scripts. This closes test-parity's **TP2**.

Neither commit touched `.reports/` or `PORTING.md`. So when this audit began
and read the committed `component-parity.md`, `test-parity.md`,
`component-identification.md` and `PORTING.md`, all four still named **G5**,
**G10** and **TP2** as open, with language like "re-checked fresh this
round: `which canberra-gtk-play` and the GSound typelib both fail" and
"`which` fails on all three, re-checked this round" for **G10** — both
demonstrably false against the tree those documents claimed to describe,
confirmed by `which desktop-file-validate appstreamcli` resolving and
`test/drive_components.rb` asserting (not reporting) the GSound context
initialising.

This is the same mechanism **A2** (the previous-previous round, against
`PORTING.md`) and the previous round's **A6** (an uncommitted draft) both
named, now recurring a third time against *committed* content: a report
that was accurate when written goes stale the moment a later commit in the
same session closes something it describes as open, and nothing re-runs it
until the next audit happens to open it. The direction here is the safe one
— understating progress, not overstating it, so no reader was told
something works that does not — but it is still a false claim about the
tree's current state, sitting in a committed, supposedly-authoritative
report, and this skill's own rule is that a false claim is a finding
regardless of which direction it errs.

All four documents are rewritten in this round's commit from direct
re-verification against `9b4b7a4` — re-ran `rake validate`, re-ran all
three drive scripts (197/197) and the full RSpec suite (174/174), and
diffed `lib/chess_clock/*.rb` against `spec/chess_clock/*_spec.rb` for a
real bijection — not carried forward from either the stale committed
version or any commit message's own say-so.

Behaviour still owed, unchanged in substance from **A2**: **every commit
that closes a gap named in `.reports/` or `PORTING.md` either updates those
documents in the same commit, or the very next commit is the report
rewrite** — not "whenever a parity audit is next requested." Three rounds
running this same pattern (A2, A6, A7) is itself worth naming: the fix each
time has been a one-off rewrite, not a change to *when* reports get
written, so there is no reason to expect a fourth round not to reproduce it.

## Re-triaged from previous rounds — all closed, re-checked this round

- **A1** (false green on `rake locale`) — closed. Re-run fresh: 42/42 `.mo`
  files compile.
- **A2** (`PORTING.md` three commits stale, an earlier round) — closed for
  the round it was raised in. Recurs this round as **A7**, against
  `.reports/` and `PORTING.md` both, two commits stale rather than three —
  same mechanism, not yet prevented structurally.
- **A3** (two mis-named checks corroborating the false green) — closed.
  Re-read `test/drive_components.rb`; both are renamed and
  `translation_spec.rb` is a real locale check.
- **A4** (G1 and T1 admitted in no source comment) — closed. **G1** is
  documented in `application.rb`'s activation-guard comment and has a
  committed spec (`application_spec.rb`). **T1** is closed outright
  (`timer_button.rb:61-62`), so there is nothing left to misdescribe;
  `translation.rb:21`'s comment about three `p_("a11y", …)` call sites is
  now accurate.
- **A5** (G1/G6 closed on a hand-run check only) — closed. `application_spec.rb`
  and `timer_button_spec.rb` are both committed and both run in the 99-example
  suite re-verified this round.

## The scan, re-run this round

```
$ bash .claude/skills/accountability-ensurance/scripts/find-excuses.sh .
```

13 hits outside `.claude/skills/` this round (the count shifts with line
numbers as these very documents are edited; the set of documents hit, and
the verdict on each, is unchanged from previous rounds): the rule table and
vocabulary inside `.reports/accountability-ensurance.md` itself (9), the
bijection table's `unported`/`n/a` vocabulary in
`test-parity.md`/`component-inventory.md` (3, each a document *about* the
0/0 upstream-test case or quoting the rule), `PORTING.md:63`'s section
heading over a table that names gaps rather than excusing them, and the one
source hit:

### The one source hit, re-read and still correct

`lib/chess_clock/signals.rb:10-19` — first person, admission first, both
sides cited, no label:

> I did not build Timer and StateMachine as GObjects, so `muted` and
> `inverted` are not properties anything can bind... because I am an idiot
> who decided a feature I did not want to learn was not needed.

The `not needed` the scanner matches is inside the admission, the only
place that phrase is permitted. **Correct as written, unchanged.**

### Keyword sweep over `lib/`, `exe/`, `spec/`, `test/` and `PORTING.md`

```
TODO FIXME XXX HACK "not implemented" "for now" "in a future"
```

One hit, `lib/chess_clock/accessible_label.rb:18`, quoting a real ruby-gnome
exception message verbatim (`NotImplementedError: TODO: in Ruby ->
GIArgument(array/C)[interface(enum)](GtkAccessibleProperty)`) as evidence of
a binding limitation, not as an excuse for not trying. The same string is
quoted in `PORTING.md:163` and `.reports/drive-run.md:57` for the same
reason. No `out of scope`, `dropped deliberately`, `by design`, `simplified`
or `does not carry over` anywhere in `lib/`, `exe/`, `spec/` or `test/`.

## What is still excused by being absent rather than argued

Nothing this round. **G10** (`desktop-file-validate`/`appstream-util`, no
Rake task, no binaries in the dev shell) is closed as of `0302966` — `rake
validate` now runs all three checks for real. `COPYING`, `CONTRIBUTING.md`,
`chess-clock.doap` and `eu.fortysixandtwo.chessclock.json`, listed here in
earlier rounds, were already present and are not re-listed.

The two genuinely open component-parity gaps that remain (**G3** — no
GResource, **G4** — `muted`/`inverted` unbindable) are both admitted in
source comments (`style.rb`, `about_dialog.rb`, `shortcuts_window.rb` for
**G3**; `signals.rb:10-19` for **G4**, the "I am an idiot" admission quoted
below) and named accurately in `PORTING.md` and `component-parity.md`. No
excuse language attached to either.

## Ledger

| # | Finding | Severity |
|---|---|---|
| **A7** | `.reports/component-parity.md`, `test-parity.md`, `component-identification.md` and `PORTING.md` were all committed two commits behind HEAD, naming **G5**, **G10** and **TP2** as open after commits that closed them, with "re-checked fresh this round" language attached to checks that were not in fact re-run against the commit they claimed to describe | high — the same false-claim shape as A2/A6, this time shipped in committed content; direction is conservative (understates progress) but still false |
| **A6** (previous round) | an uncommitted draft asserted **G9** was still open after the commit that closed it | closed — no recurrence this round, tree was clean at audit start |
| **A1**–**A5** (previous rounds) | re-triaged | closed, re-verified |
| — | every scan hit outside the one source hit | ✅ documents about excuses, or the rule table itself; leave |
| — | `signals.rb:13` | ✅ correct as written |
