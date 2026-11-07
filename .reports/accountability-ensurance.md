# Accountability ensurance — Chess Clock

| | |
|---|---|
| Port | `ruby` @ `28007cd` |
| Scanned | `lib/`, `exe/`, `spec/`, `test/`, `.reports/`, `PORTING.md`, `FINDINGS.md`, plus the working tree's uncommitted state at the start of this audit |
| Scan | `accountability-ensurance/scripts/find-excuses.sh .` → 18 hits outside `.claude/skills/`, all previously triaged; re-triaged this round, same verdicts |
| Verdict | **NOT CLEAN — 1 new finding (A6: a stale, uncommitted draft contradicting a closed gap), 1 recurring pattern (A2-style report staleness, this round's instance: pre-audit `test-parity.md`/`translation-parity.md`/`accountability-ensurance.md` all pinned three commits behind HEAD before this audit rewrote them). Previous rounds' A1–A5 are closed.** |

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

## Recurring pattern — `test-parity.md`, `translation-parity.md` were three commits stale before this round

Before this audit rewrote them, `.reports/test-parity.md` and
`.reports/translation-parity.md` both still read `Port | ruby @ 68fd69d`
and reported **TR1/T1/T2/T3 as open** and **88 RSpec examples**, despite
three intervening commits (`daf57ec`, `f9be8a7`, `3fc88ce`, `e25a1b2`,
`28007cd`) that closed all four translation gaps, added three spec files
(99 examples total) and closed **G9**. `.reports/accountability-ensurance.md`
itself was equally stale.

This is the same class of failure the previous round's own **A2** finding
named against `PORTING.md`: a report commits in the same round as the fix it
should describe, and the *other* reports in `.reports/` are left untouched
until the next explicit parity audit, so for however many commits pass in
between, a reader of `translation-parity.md` is told the app is English-only
in every locale when it is not. `PORTING.md` itself was kept current this
time (it correctly states all four translation gaps and **G9** as closed as
of `28007cd`) — the gap was specifically in the four `.reports/*.md`
documents that a translation/component/test/accountability audit is
supposed to be the source of truth for, and those are the ones this round's
commit brings back in line with the tree.

Behaviour still owed, unchanged from the previous round's **A2**: **every
report in `.reports/` is re-verified and re-committed in the same round as
any commit that closes a gap it names, not only in the round that happens to
run this skill next.**

## Re-triaged from previous rounds — all closed, re-checked this round

- **A1** (false green on `rake locale`) — closed. Re-run fresh: 42/42 `.mo`
  files compile.
- **A2** (`PORTING.md` three commits stale) — closed as of this tree.
  `PORTING.md` names the current gap set (G3, G4, G5, G10) and the current
  closed set (G1, G6, G8, G9, G12, TR1, T1, T2, T3) correctly as of `28007cd`.
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

18 hits outside `.claude/skills/`, identical set to previous rounds: the
rule table and vocabulary inside `.reports/accountability-ensurance.md`
itself (10), the bijection table's `unported`/`n/a` vocabulary in
`test-parity.md`/`component-inventory.md`/`component-parity.md` (4, each a
document *about* the 0/0 upstream-test case or quoting the rule), `PORTING.md
:63`'s section heading over a table that names gaps rather than excusing
them, and the one source hit:

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

One upstream deliverable has no counterpart and no source-file admission,
only a ledger row:

- **`desktop-file-validate` / `appstream-util validate`** — upstream runs
  both at build time from `data/meson.build`; the `Rakefile` runs neither,
  and neither binary exists in the dev shell to validate against even if it
  did (component-parity **G10**). No file under `lib/` or `exe/` admits this;
  it is recorded only in `component-parity.md` and `PORTING.md`.

`COPYING`, `CONTRIBUTING.md`, `chess-clock.doap` and
`eu.fortysixandtwo.chessclock.json`, listed here in previous rounds, are now
all present in the tree (**G8**, **G9** closed) and are removed from this
list.

## Ledger

| # | Finding | Severity |
|---|---|---|
| **A6** | an uncommitted, never-finished draft of two `.reports/` files asserted **G9** was still open after the commit that closed it, and claimed the check behind that assertion was fresh when it was not | high — exactly the false-claim shape this skill exists to catch, caught before it was committed |
| — | `test-parity.md`, `translation-parity.md`, this file — all three commits stale before this round | high — now closed by this round's rewrite |
| **A1**–**A5** (previous rounds) | re-triaged | closed, re-verified |
| — | every scan hit outside the one source hit | ✅ documents about excuses, or the rule table itself; leave |
| — | `signals.rb:13` | ✅ correct as written |
