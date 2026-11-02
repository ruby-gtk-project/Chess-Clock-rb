# Translation parity — Chess Clock

| | |
|---|---|
| Upstream | `main` @ `775f046` |
| Port | `ruby` @ `270aa8a` |
| Domain | `chess-clock` (from `po/meson.build`) |
| Domain the port uses | **none** — no `bindtextdomain`, no gettext dependency |
| Upstream messages | **50** |
| Ported | **0** |
| Gaps | **50** |
| Extra (untranslated) | 0 |
| Upstream occurrences | 52 across 50 messages (1 reused: `Chess Clock`, 3 sites) |
| Port occurrences | **0** |
| Upstream languages | **42** `.po` files, **2,004 translated**, 32 untranslated, 0 fuzzy |
| Languages shipped by the port | **0 of 42** |
| Plurals / contexts | 0 plural, 11 with msgctxt (8 `shortcut window`, 3 `a11y`) |
| Build command | none exists |
| Checks that did not run | `msgfmt` is not installed in this shell, so no catalogue was compiled or validated. The `gtk4`/`adwaita` gems are not installed, so the app was never launched under a non-English locale. Neither check can pass today anyway — there is no `po/` — but both are recorded as unrun rather than as passed. |

Generated documents: `.reports/upstream-catalogue.yaml`,
`.reports/port-catalogue.yaml`, `.reports/translation-parity.yaml`.
`summary.parity: false`.

## The headline

**0 of 42 languages. 0 of 2,004 translated strings. 0 of 50 messages.**

The `ruby` branch has no `po/` directory, no `LINGUAS`, no `POTFILES.in`, no
gettext gem in the `Gemfile` or the gemspec, and no `bindtextdomain` call
anywhere. A census of the port returns zero rows. Every user-visible string in
`lib/` is a bare Ruby literal.

What makes this the *recoverable* shape of the failure, and worth saying so the
next person does not re-derive it: **40 of the 50 upstream msgids already exist
in `lib/` byte for byte.** The port transcribed upstream's English instead of
rewriting it, and there is no string interpolation inside any of them. So 40 of
these 50 rows close by wrapping an existing literal in a marker — not by
authorship. The remaining 10 are the ones that live in files the port does not
have at all (`data/`), and they cannot close until those files exist.

One string is reworded and must move back to upstream's bytes:
`about_dialog.rb:24` writes `Time games of over-the-board chess.` where the
msgid is `Time games of over-the-board chess`. The trailing period makes it a
different hash key, which discards 42 translations of the app's own summary
while the English still reads correctly.

The eight `shortcut window` strings are the only *marked* strings in the port —
`shortcuts_window.rb` carries them inside a GtkBuilder XML heredoc with
`translatable="yes" context="shortcut window"`. They are still gaps: GtkBuilder
resolves a translatable property against the default textdomain, and the port
never binds one, so those eight stay English in all 42 languages no matter what
`po/` is added later. Marking them is not the fix; binding the domain is.

## Upstream census, cross-checked

| Source | Messages |
|---|---:|
| `src/gtk/window.ui` | 18 |
| `src/gtk/timecontrolentry.ui` | 11 |
| `src/gtk/help-overlay.ui` | 8 |
| `data/eu.fortysixandtwo.chessclock.metainfo.xml.in` | 9 |
| `src/timerbutton.py` | 2 |
| `src/main.py` | 1 |
| `data/eu.fortysixandtwo.chessclock.desktop.in` | 1 |

One message per row, grouped under the file the census lists first: `Chess Clock`
reaches three sites (`window.ui:6`, the `.desktop` `Name=` and the metainfo
`<name>`) and is counted once, under `window.ui`.

Note that `Player white timer` and `Player black timer` each exist **twice** as
distinct keys — once with `msgctxt "a11y"` (from `window.ui`) and once with no
context (from `timerbutton.py`, which relabels the button as the sides swap).
Four rows, not two. Merging them would be a gap in disguise, and the port's
`TimerButton::ACCESSIBLE_LABELS` currently supplies the un-contexted pair only.

Cross-checks, all clean — upstream's catalogue is in good order and the port is
inheriting a healthy asset, not a broken one:

- Every one of the 50 source msgids appears in at least one `.po`. Nothing has
  gone unextracted.
- `po/POTFILES.in` is complete: no file with translatable strings is missing
  from it.
- `LINGUAS` matches the 42 `.po` files exactly.
- Zero fuzzy entries across all 42 files.
- No file has CRLF terminators.
- `de.po` carries exactly one msgid the source no longer has — `Clara Hobbs`,
  from `data/com.clarahobbs.chessclock.appdata.xml.in:33`, a file from before
  the app id changed. That is the expected "deleted upstream" case.

## The ledger

`Uses` is `<upstream call sites> → <port call sites>`. Every row is a **gap**;
`Text still owed` is the byte-identical English to transcribe.

### src/gtk/window.ui → `lib/chess_clock/window.rb` + `lib/chess_clock/primary_menu.rb` (18 messages)

| # | msgctxt | msgid | Kind | Uses | Text still owed |
|---|---|---|---|---|---|
| 1 | `a11y` | `Select time controls` | single | 1 → 0 | Select time controls |
| 2 | — | `Main Menu` | single | 1 → 0 | Main Menu |
| 3 | — | `Toggle Pause` | single | 1 → 0 | Toggle Pause |
| 4 | `a11y` | `Player white timer` | single | 1 → 0 | Player white timer |
| 5 | `a11y` | `Player black timer` | single | 1 → 0 | Player black timer |
| 6 | — | `_New Time Control` | single | 1 → 0 | _New Time Control |
| 7 | — | `_Restart Timer` | single | 1 → 0 | _Restart Timer |
| 8 | — | `_Mute Alert Sound` | single | 1 → 0 | _Mute Alert Sound |
| 9 | — | `_Keyboard Shortcuts` | single | 1 → 0 | _Keyboard Shortcuts |
| 10 | — | `_About Chess Clock` | single | 1 → 0 | _About Chess Clock |
| 11 | — | `Welcome to Chess Clock` | single | 1 → 0 | Welcome to Chess Clock |
| 12 | — | `Select time controls below to get started` | single | 1 → 0 | Select time controls below to get started |
| 13 | — | `Chess Clock` | single | 3 → 0 | Chess Clock |
| 14 | — | `Time control method` | single | 1 → 0 | Time control method |
| 15 | — | `Increment` | single | 1 → 0 | Increment |
| 16 | — | `Bronstein delay` | single | 1 → 0 | Bronstein delay |
| 17 | — | `Simple delay` | single | 1 → 0 | Simple delay |
| 18 | — | `Start Game` | single | 1 → 0 | Start Game |

### src/gtk/timecontrolentry.ui → `lib/chess_clock/time_control_entry.rb` (11 messages)

| # | msgctxt | msgid | Kind | Uses | Text still owed |
|---|---|---|---|---|---|
| 19 | — | `Thirty minutes per side, plus zero seconds per turn` | single | 1 → 0 | Thirty minutes per side, plus zero seconds per turn |
| 20 | — | `Thirty minutes per side, plus twenty seconds per turn` | single | 1 → 0 | Thirty minutes per side, plus twenty seconds per turn |
| 21 | — | `Main time minutes` | single | 1 → 0 | Main time minutes |
| 22 | — | `Main time seconds` | single | 1 → 0 | Main time seconds |
| 23 | — | `Increment seconds` | single | 1 → 0 | Increment seconds |
| 24 | — | `One minute per side, plus zero seconds per turn` | single | 1 → 0 | One minute per side, plus zero seconds per turn |
| 25 | — | `Two minutes per side, plus one second per turn` | single | 1 → 0 | Two minutes per side, plus one second per turn |
| 26 | — | `Five minutes per side, plus zero seconds per turn` | single | 1 → 0 | Five minutes per side, plus zero seconds per turn |
| 27 | — | `Five minutes per side, plus three seconds per turn` | single | 1 → 0 | Five minutes per side, plus three seconds per turn |
| 28 | — | `Ten minutes per side, plus zero seconds per turn` | single | 1 → 0 | Ten minutes per side, plus zero seconds per turn |
| 29 | — | `Ten minutes per side, plus five seconds per turn` | single | 1 → 0 | Ten minutes per side, plus five seconds per turn |

### src/gtk/help-overlay.ui → `lib/chess_clock/shortcuts_window.rb` (8 messages)

| # | msgctxt | msgid | Kind | Uses | Text still owed |
|---|---|---|---|---|---|
| 30 | `shortcut window` | `Game` | single | 1 → 0 | Game |
| 31 | `shortcut window` | `New Time Control` | single | 1 → 0 | New Time Control |
| 32 | `shortcut window` | `Restart Timer` | single | 1 → 0 | Restart Timer |
| 33 | `shortcut window` | `General` | single | 1 → 0 | General |
| 34 | `shortcut window` | `Open Main Menu` | single | 1 → 0 | Open Main Menu |
| 35 | `shortcut window` | `Show Shortcuts` | single | 1 → 0 | Show Shortcuts |
| 36 | `shortcut window` | `Close Window` | single | 1 → 0 | Close Window |
| 37 | `shortcut window` | `Quit` | single | 1 → 0 | Quit |

### src/timerbutton.py → `lib/chess_clock/timer_button.rb` (2 messages)

| # | msgctxt | msgid | Kind | Uses | Text still owed |
|---|---|---|---|---|---|
| 38 | — | `Player white timer` | single | 1 → 0 | Player white timer |
| 39 | — | `Player black timer` | single | 1 → 0 | Player black timer |

### src/main.py → `lib/chess_clock/about_dialog.rb` (1 messages)

| # | msgctxt | msgid | Kind | Uses | Text still owed |
|---|---|---|---|---|---|
| 40 | — | `translator-credits` | single | 1 → 0 | translator-credits |

### data/eu.fortysixandtwo.chessclock.desktop.in → **no port file** — waits on the component gap (1 messages)

| # | msgctxt | msgid | Kind | Uses | Text still owed |
|---|---|---|---|---|---|
| 41 | — | `chess;game;clock;timer;` | single | 1 → 0 | chess;game;clock;timer; |

### data/eu.fortysixandtwo.chessclock.metainfo.xml.in → **no port file** — waits on the component gap (9 messages)

| # | msgctxt | msgid | Kind | Uses | Text still owed |
|---|---|---|---|---|---|
| 42 | — | `Chess Clock is a simple application to provide time control for over-the-board chess games. Intended for mobile use, players select the time control settings desired for their game, then the black player taps their clock to start white's timer. After each player's turn, they tap the clock to start their opponent's, until the game is finished or one of the clocks reaches zero.` | single | 1 → 0 | Chess Clock is a simple application to provide time control for over-the-board chess games. Intended for mobile use, players select the time control settings desired for their game, then the black player taps their clock to start white's timer. After each player's turn, they tap the clock to start their opponent's, until the game is finished or one of the clocks reaches zero. |
| 43 | — | `chess` | single | 1 → 0 | chess |
| 44 | — | `clock` | single | 1 → 0 | clock |
| 45 | — | `game` | single | 1 → 0 | game |
| 46 | — | `The main screen in a portrait aspect ratio, showing one timer rotated 180 degrees` | single | 1 → 0 | The main screen in a portrait aspect ratio, showing one timer rotated 180 degrees |
| 47 | — | `The main screen, showing timers for the white and black players of a chess game` | single | 1 → 0 | The main screen, showing timers for the white and black players of a chess game |
| 48 | — | `The time control selection screen` | single | 1 → 0 | The time control selection screen |
| 49 | — | `Time games of over-the-board chess` | single | 1 → 0 | Time games of over-the-board chess |
| 50 | — | `timer` | single | 1 → 0 | timer |

## What closing these gaps requires, in order

1. **Copy upstream's whole `po/` across unchanged** — all 42 `.po`, `LINGUAS`,
   and `POTFILES.in` rewritten to the Ruby paths. Do this first: it makes every
   later row verifiable instead of hopeful.
2. **Keep the domain `chess-clock`.** Not `chess-clock-rb`. The `.mo` lookup key
   is the domain, and the catalogues are upstream's.
3. **Bind it.** Add the `gettext` gem, call `bindtextdomain`/`textdomain` in
   `exe/chess-clock` the way `src/chess-clock.in` does, and add a Rakefile task
   that compiles one `.mo` per language. Until this exists, a marked string is
   still an English string — which is exactly the state the eight
   `shortcut window` titles are in today.
4. **Transcribe the 40 rows whose bytes are already in `lib/`.** Wrap the
   existing literal; never retype it.
5. **Fix `about_dialog.rb:24`** to upstream's bytes — drop the trailing period.
6. **Build `data/`** (`.desktop.in`, metainfo, gschema). Ten rows wait on that
   component gap and cannot close before it; the `Uses` cell for each says so.
7. **Add the port's own `POTFILES.in` completeness check** to the task that runs
   the tests, using the census rather than upstream's grep (upstream's CI regex
   `\(gettext\|[^I_)]_\)(` requires a paren immediately after the marker and
   would miss ordinary Ruby spacing).
8. **Do not copy `POTFILES.skip`.** A Ruby port generates nothing.

## Extra

None. The port emits no message upstream does not have — because it emits none
at all.

## Reconciliation notes

- `uses_mismatch` is 0 and is not a pass condition either way; all 50 keys have
  0 port call sites, so there is nothing to investigate against
  `component-parity.md` yet. When the markers land, the `Chess Clock` row
  (3 upstream sites) is the one to re-read.
- `totals.unresolved` is **0** on both sides, so the ledger is written against a
  complete census. No message was censused by hand.
- Translations arrive through l10n.gnome.org against **upstream**, not this
  fork, which will never be registered there. The copy taken in step 1 is a
  snapshot: record `775f046` as the sha it came from, so the next refresh is a
  diff rather than archaeology. Any string the port invents will never be
  translated by anyone.
