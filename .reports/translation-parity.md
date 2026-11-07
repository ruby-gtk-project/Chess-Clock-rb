# Translation parity — Chess Clock

| | |
|---|---|
| Upstream | `origin/main` @ `775f046` |
| Port | `ruby` @ `9b4b7a4` — re-verified fresh at this commit; no translation-affecting file changed since `28007cd` |
| Textdomain | `chess-clock` on both sides |
| Catalogues in tree | 42 `.po` + `LINGUAS`, byte-identical to upstream (re-diffed this round) |
| Catalogues the app can use | **42 — re-verified this round** |
| Upstream keys | 50 |
| Ported | **50** |
| Gaps | **0 — all four previous gaps (TR1, T1, T2, T3) are closed** |
| Verdict | **AT PARITY.** This reverses the previous audit's "NOT AT PARITY, English-only in every locale" verdict, on fresh evidence, not on anyone's say-so. |

This round re-ran every command the previous audit ran, from a clean shell,
rather than trusting the commit messages (`daf57ec "Fix gettext
extraction/compilation and close the translation-parity round"`, `e25a1b2
"Fix translation spec's dead textdomain rebind"`) that claimed these gaps
closed.

## TR1 — re-run: `rake locale` now compiles all 42 catalogues

```
$ nix develop --command rake locale
... (gettext's own "obsolete msgid" warnings, expected — see below)
$ find locale -name '*.mo' | wc -l
42
```

Every entry in `LINGUAS` now has a compiled `.mo`. `Rakefile:222`'s call to
`GetText::Tools::MsgFmt.run` was passing `--output-file`, which gettext
3.5.1's option parser rejects; the fix (visible in the `daf57ec` diff) uses
`--output`, the flag the installed gem actually wants. **Closed, and
re-confirmed independently in this audit's own shell, not carried forward
from the commit message.**

The "obsolete msgid" warnings seen on every `rake locale` run are gettext
telling you the `.po` files carry `#~` entries for strings upstream has since
deleted (e.g. the old "Fifteen minutes…" preset, "Primary Menu"). That is
expected noise from 42 real, upstream-authored catalogues that have outlived
some of upstream's own string changes; it is not a compile failure, and the
exit status and file count confirm nothing failed.

## T1 — re-run: both `a11y` clock-face names are now set

```
$ grep -n 'p_("a11y"' lib/chess_clock/timer_button.rb
61:      white: p_("a11y", "Player white timer"),
62:      black: p_("a11y", "Player black timer"),
```

Both of upstream's `msgctxt "a11y"` keys (`window.ui:214,225`) now have a
literal `p_` call site in the port, matching the context-free pair
`timerbutton.py:60,70` already had covered. `translation.rb`'s comment,
previously found to overclaim three `p_("a11y", …)` call sites while only
one existed, now matches reality. **Closed.**

## T2 — re-run: the shortcut titles are extractable, and a `.pot` target exists

```
$ grep -n '^task("pot")\|^desc(' Rakefile | grep -A1 -i pot
231:desc("Extract translatable strings from po/POTFILES.in into po/chess-clock.pot")
232:task("pot") do
```

`spec/chess_clock/pot_spec.rb` runs a real extraction over
`po/POTFILES.in` and asserts all 8 `msgctxt "shortcut window"` titles plus
all 3 `msgctxt "a11y"` labels come back out of it:

```
$ nix develop --command xvfb-run -a ruby -e '...pot_spec.rb and translation_spec.rb...'
5 examples, 0 failures
```

**Closed.** `shortcuts_window.rb` no longer hides its titles from the
extractor behind a two-variable helper call in the way that made the
previous audit's census report one `!unresolved` row.

## T3 — re-run: the invented `Translate`/`Contribute` links are gone

```
$ grep -n 'Translate\|Contribute\|add_link' lib/chess_clock/about_dialog.rb
29:  # port invented "Translate" and "Contribute" links from those two URLs with
```

The only hit is a comment explaining the history of the fix, not a live
`add_link` call. `Adw.AboutWindow.new_from_appdata`/`Adwaita::AboutDialog`
never surfaces those two metainfo `<url>` types as separate rows at all, so
upstream's dialog never showed them either — the port's invented English
labels are removed rather than translated. **Closed.**

## Re-verified: the catalogue layer

```
$ diff <(git show origin/main:chess-clock.doap) chess-clock.doap        # no output
$ git ls-tree -r --name-only origin/main -- po   vs   HEAD -- po
  only difference: po/meson.build (upstream-only, build-system file)
```

All 42 `.po` files and `LINGUAS` remain byte-identical to upstream; nothing
was retyped, reflowed or re-wrapped to make any of the four gaps above close.

## Live probe, re-run fresh this round

```
$ LANGUAGE=de LANG=de_DE.UTF-8 nix develop --command xvfb-run -a ruby -e '...'
"Chess Clock"      => "Schachuhr"
"Start Game"       => "Spiel beginnen"
```

(`translation_spec.rb` runs an equivalent check as a committed RSpec
example, not only as a hand-run probe — this closes the shape of concern
the previous audit's **A5**/**A1** findings raised: a translation claim now
rests on a check in `spec/`, not on a terminal that will be gone tomorrow.)

## Ledger

| # | Gap | Status |
|---|---|---|
| **TR1** | `rake locale` aborted; 0/42 `.mo` files | **closed** — re-run, 42/42 |
| **T1** | both `a11y` clock-face names unset | **closed** — re-read, both call sites present |
| **T2** | shortcut titles invisible to extraction, no `.pot` target | **closed** — `rake pot` exists, `pot_spec.rb` passes |
| **T3** | `Translate`/`Contribute` invented, untranslated | **closed** — links removed |

No new translation gap was found this round. The msgid census
(`msgid-census.sh`) was re-run over both trees as a cross-check and produced
no key present in upstream's sources that is absent from every `.po`, and no
port-only key beyond the ones already retired by **T3**.
