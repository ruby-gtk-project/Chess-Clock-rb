# Accountability ensurance — Chess Clock

| | |
|---|---|
| Port | `ruby` @ `2ccf565` |
| Scan | `accountability-ensurance/scripts/find-excuses.sh .` → 14 hits |
| Verdict | **1 live gap (A1); every other gap is admitted in the required form but 11 are still open** |

## The scan

14 hits, of which 12 are in `.reports/*.md` and are this skill's own rule table
quoted in a ledger — documents *about* excuses, which the skill says not to
rewrite. One is in a report heading. That leaves one hit in the port's own
source.

| File:line | Phrase | Verdict |
|---|---|---|
| `lib/chess_clock/signals.rb:13` | `not needed` | **A1 — rewrite** |
| `.reports/component-parity.md:102,171` | `no Ruby equivalent`, `skipping` | rule table in a ledger — leave |
| `.reports/component-identification.md:41` | `n/a`, `by design` | rule table in a ledger — leave |
| `.reports/component-inventory.md:139` | `skipping` | rule table in a ledger — leave |
| `.reports/accountability-ensurance.md:7,56,143,193,205,224` | the rule table itself | leave |

Clean on the patterns that matter most: no `out of scope`, no
`dropped deliberately`, no `simplified`, no `not applicable`, no
`does not carry over`, no `by design` anywhere in `lib/`, `exe/`, `spec/` or
`test/`. The `TODO` / `FIXME` / `XXX` / `HACK` / `not implemented` /
`for now` / `in a future` sweep over `lib/` and `exe/` returns **zero** hits.
The two `later` hits are the English word in a sentence about alert thresholds
and about geometry recording, not deferrals.

### A1 — the one live hit

`lib/chess_clock/signals.rb:11-14`:

> I did not build Timer and StateMachine as GObjects, so `muted` and
> `inverted` are not properties anything can bind … **because I am an idiot who
> decided a feature I did not want to learn was not needed.**

The admission, the attribution and the upstream/port citation are all present
and in the right order. The problem is the trailing clause: *"decided … was not
needed"* names a decision and a need-assessment in the same breath. A reader
skimming for whether this is settled finds the two words the scan exists to
catch. The sentence must not contain a defensible-sounding judgement even when
it is being attributed to the writer's stupidity — "idiot who decided X was not
needed" still records that X was evaluated.

**Rewrite to:** *"…because I am an idiot who could not be bothered to learn how
GObject properties are declared from Ruby."* Same attribution, no
need-assessment, no decision.

## Audit of the admissions

Each file below carries a first-person admission with an upstream citation and
a port citation. Every one is in the required form. **None of them closes a
gap**, and this section exists to check that each still appears in the parity
ledger rather than only in a comment.

| File | Admission | In the ledger? |
|---|---|---|
| `lib/chess_clock/application.rb:62-67` | not built on `Adwaita::Application`; style loading and help-overlay wiring done by hand | ✅ **G3** |
| `lib/chess_clock/about_dialog.rb:16-25` | metainfo fields retyped instead of read | ✅ **G3**, **G7** |
| `lib/chess_clock/style.rb:14-21` | no GResource; stylesheets inlined and high-contrast switched by hand | ✅ **G3** |
| `lib/chess_clock/settings.rb:11-20` | GSettings replaced by a JSON file | ✅ **G2** |
| `lib/chess_clock/signals.rb:11-19` | `Timer`/`StateMachine` not GObjects; `muted`/`inverted` unbindable | ✅ **G4**, and **A1** above |
| `lib/chess_clock/alert_sound.rb:20-29` | GSound path never executed; fallbacks are a different sound | ✅ **G5** |
| `lib/chess_clock/window.rb:37-41` | frame-clock callbacks installed in a different place, untested on both sides | ✅ **G11** |
| `lib/chess_clock/shortcuts_window.rb:28-34` | titles looked up in Ruby, not by GtkBuilder | ✅ **T2** |
| `FINDINGS.md` | 8 sections: 2 open, 4 substitutions, 2 divergences, 1 resolved, 1 still-to-carry | ✅ all mapped below |

### `FINDINGS.md` cross-check

| `FINDINGS.md` section | Ledger row |
|---|---|
| Open: the alert sound does not demonstrably play | **G5** |
| Open: nothing has been rendered or driven | **G11**, **TP1** |
| Substitution: GSettings replaced by a JSON file | **G2** |
| Substitution: no GResource | **G3** |
| Substitution: plain Ruby models instead of GObjects | **G4** |
| Substitution: GtkBuilder's translatable properties | **T2** |
| Divergence: where the frame-clock callbacks are installed | noted under **G11** |
| Divergence: the About window's release notes version | port ahead of upstream; recorded in component-parity, not a gap |
| Divergence: two link titles with no msgid | **T3** |
| Resolved: the application id | verified — `APP_ID = "eu.fortysixandtwo.chessclock"` at `application.rb:28`, and `data/` is byte-identical to upstream |
| Still to carry over from upstream's build | **G10** |

`FINDINGS.md`'s own preamble states the rule correctly: *"Nothing in this file
closes a gap."* It is doing its job.

## Gaps that are admitted nowhere

These are open gaps with **no** admission in any source comment or in
`FINDINGS.md` — the most dangerous class, because there is nothing for the next
reader to find.

| # | Gap | Where it should be admitted |
|---|---|---|
| **A2** | **G1** — `Application`'s activate handler rebuilds the window on every activation; upstream raises the one that is open. No comment anywhere mentions the missing guard, and `application.rb:43-55` reads as deliberate. | a first-person admission at `lib/chess_clock/application.rb:42`, plus a `FINDINGS.md` row |
| **A3** | **G6** — `set_css_name("button")` and `set_accessible_role(…BUTTON)` are absent from `TimerButton`. The class comment lists the CSS classes it carries and says nothing about the two calls it dropped. | `lib/chess_clock/timer_button.rb` class comment |
| **A4** | **G8** — no `COPYING`, no `CONTRIBUTING.md`, in a GPL-3 derivative whose gemspec declares `GPL-3.0-or-later` and whose About window links to a Contribute page that does not exist here. Mentioned nowhere. | `FINDINGS.md`, and the About dialog's `LINKS` comment |
| **A5** | **G9** — no `chess-clock.doap`, no Flatpak manifest, no CI. Mentioned nowhere. | `FINDINGS.md` |
| **A6** | **T1** — the two `msgctxt "a11y"` timer labels are set by no port file. `timer_button.rb`'s `announce` comment explains why the label changes with the colour and does not mention that upstream also sets it from a second, context-qualified msgid. | `lib/chess_clock/timer_button.rb` |
| **A7** | **TP2** — eight of eighteen units have no spec, including `Window`, the largest file in the port. `spec/README.md` describes the harness and claims nothing about coverage, which is honest; nothing records the hole. | `FINDINGS.md` |

## Verdict

The port's accountability discipline is unusually good: the admissions that
exist are in the required first person, carry both citations, and are mirrored
in the parity ledger. The scan finds almost nothing to rewrite.

That is not the same as being at parity, and the second table is why this
report is not clean. **Six open gaps are recorded in no document at all**
(A2–A7), and one live phrase needs rewriting (A1). An undocumented gap is worse
than a badly-worded one: there is no sentence for the next agent to read, so the
omission is inherited as a fact about the project without anyone having to be
persuaded of it.
