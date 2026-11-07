# Chess Clock — component inventory

Surveyed against `origin/main` (Python/GTK4/Libadwaita, GNOME Chess Clock,
`eu.fortysixandtwo.chessclock`) for the `ruby` port. Per the
`component-identification` skill: components are joined across their backing
source file *and* their `.ui` file, listed in the order a user meets them
(window first, then its pages/dialogs/menus, then supporting non-widget
pieces, then data/translation plumbing).

## Summary

Every upstream unit that contributes a user-facing component already has a
corresponding `lib/chess_clock/*.rb` file on `ruby`. This is a **mature
port at the file-mapping level** — no missing component files were found.
(This survey does not re-verify widget-by-widget/signal-by-signal fidelity
inside each file; that is the job of `component-parity`, not this inventory.)

## Components

| # | Upstream file(s) | → `lib/*.rb` | Kind | Present? |
|---|---|---|---|---|
| 1 | `src/window.py` + `src/gtk/window.ui` | `lib/chess_clock/window.rb` | window (`ChessClockWindow`, `Adw.ApplicationWindow`) — main stack with the time-control chooser page and the timer page, header bar revealer, window controls, menu button, play/pause button, timer box (`a_timer`/`b_timer`), `AdwBreakpoint` for narrow layout | ✅ exists |
| 2 | `src/main.py` | `lib/chess_clock/application.rb` | application (`ChessClockApplication`, `Adw.Application`) — holds `app.quit`, `app.about` actions and their accelerators | ✅ exists |
| 3 | `src/timerbutton.py` + `src/gtk/timerbutton.ui` | `lib/chess_clock/timer_button.rb` | widget (`ChessClockTimerButton`, `Gtk.Button` subclass) — per-player timer face with `AdwBreakpointBin`, minutes/colon/seconds labels, `inverted` GObject property, `white`/`black`/`running`/`expired`/`inverted` CSS classes | ✅ exists |
| 4 | `src/timecontrolentry.py` + `src/gtk/timecontrolentry.ui` | `lib/chess_clock/time_control_entry.rb` | widget (`ChessClockTimeControlEntry`, `Gtk.Box` subclass) — 8 preset time-control buttons in a grid + custom minutes/seconds/increment `GtkSpinButton`s bound to GSettings | ✅ exists |
| 5 | `src/gtk/window.ui` `<menu id="primary_menu">` | `lib/chess_clock/primary_menu.rb` | menu (New Time Control, Restart Timer / Mute Alert Sound / Keyboard Shortcuts, About) | ✅ exists |
| 6 | `src/gtk/help-overlay.ui` | `lib/chess_clock/shortcuts_window.rb` | shortcuts dialog (`GtkShortcutsWindow`) — "Game" group (New Time Control, Restart Timer), "General" group (Open Main Menu, Show Shortcuts, Close Window, Quit) | ✅ exists |
| 7 | `src/main.py` `on_about_action` (`Adw.AboutWindow.new_from_appdata`) | `lib/chess_clock/about_dialog.rb` | dialog (about window — developers, artists, translator credits, built from metainfo) | ✅ exists |
| 8 | `src/timer.py` | `lib/chess_clock/timer.rb` | non-widget model (`ChessClockTimer`, `GObject.Object`) — `changed`/`expired`/`alerted` signals, tick-driven countdown | ✅ exists |
| 9 | `src/statemachine.py` (`ChessClockStateMachine` base) | `lib/chess_clock/state_machine.rb` | non-widget model (base state machine) — `a_active`/`b_active`/`pause`/`awbb`/`abbw` signals, idle-inhibit, GSound alert hookup | ✅ exists |
| 10 | `src/statemachine.py` (`ChessClockIncrementStateMachine`) | `lib/chess_clock/increment_state_machine.rb` | non-widget model (Fischer increment variant) | ✅ exists |
| 11 | `src/statemachine.py` (`ChessClockBronsteinStateMachine`) | `lib/chess_clock/bronstein_state_machine.rb` | non-widget model (Bronstein delay variant) | ✅ exists |
| 12 | `src/statemachine.py` (`ChessClockDelayStateMachine`) | `lib/chess_clock/delay_state_machine.rb` | non-widget model (simple/US delay variant) | ✅ exists |
| 13 | `src/gtk/style.css` + `src/gtk/style-hc.css` | `lib/chess_clock/style.rb` | stylesheet loader (CSS provider setup, including the high-contrast variant) | ✅ exists |
| 14 | `src/statemachine.py` `GSound.Context` usage | `lib/chess_clock/alert_sound.rb` | behaviour (GSound alert-sound wrapper; GSound has no Ruby binding, so this is infra the port needs that upstream gets for free) | ✅ exists |
| 15 | `src/timerbutton.py` `update_property([Gtk.AccessibleProperty.LABEL], …)` | `lib/chess_clock/accessible_label.rb` | behaviour (accessible-label helper for the two timer buttons' dynamic a11y label) | ✅ exists |
| 16 | `src/timer.py` / `src/statemachine.py` `@GObject.Signal` declarations | `lib/chess_clock/signals.rb` | infra (the port's stand-in for ad-hoc GObject signal declarations, since plain Ruby objects don't get `@GObject.Signal` for free) | ✅ exists |
| 17 | `data/eu.fortysixandtwo.chessclock.gschema.xml` | `lib/chess_clock/settings.rb` | infra (GSettings-equivalent wrapper: `control-method`, `width`, `height`, `is-maximized`, `muted`, `custom-control-minutes/seconds/increment`) | ✅ exists; schema file itself also copied to `data/` unchanged |
| 18 | `po/*.po` + `po/POTFILES.in` + translator-credits string | `lib/chess_clock/translation.rb` | infra (gettext textdomain bind, loaded first by `lib/chess_clock.rb`) | ✅ exists; `po/` catalogue (44 locales) already copied to `ruby` |
| — | `lib/chess_clock.rb` | — | root loader requiring all of the above in dependency order | ✅ exists |

## Data / packaging files (not widgets, but part of the user-facing surface)

| Upstream file | On `ruby` | Present? |
|---|---|---|
| `data/eu.fortysixandtwo.chessclock.desktop.in` | `data/eu.fortysixandtwo.chessclock.desktop.in` | ✅ |
| `data/eu.fortysixandtwo.chessclock.gschema.xml` | `data/eu.fortysixandtwo.chessclock.gschema.xml` | ✅ identical (diffed) |
| `data/eu.fortysixandtwo.chessclock.metainfo.xml.in` | `data/eu.fortysixandtwo.chessclock.metainfo.xml.in` | ✅ |
| `data/eu.fortysixandtwo.chessclock.service.in` | `data/eu.fortysixandtwo.chessclock.service.in` | ✅ |
| `data/icons/**` | `data/icons/**` | ✅ |
| `data/screenshots/**` | `data/screenshots/**` | ✅ |
| `src/chess-clock.in` (entry script) | `exe/chess-clock` | ✅ (entry point exists; not a widget, not re-verified line-by-line here) |
| `src/chess-clock.gresource.xml` | — | N/A by design — the house style never ships `.ui`/GResource files; widgets are built declaratively in `lib/*.rb` instead of loaded from compiled resources |

## Actions and accelerators cross-checked

- `app.quit` (`<primary>q`), `app.about` — both referenced in `lib/chess_clock/application.rb`.
- `win.new` (`<primary>n`), `win.restart` (`<primary>r`), `win.close` (`<primary>w`), `win.menu` (`F10`), `win.muted` (stateful boolean action bound to the `muted` GSetting), `win.show-help-overlay` — all referenced in `lib/chess_clock/window.rb`.

## What this survey did not do

- It did not diff widget-by-widget (types, CSS classes, signals, repeaters)
  inside each `lib/*.rb` file against its upstream counterpart — that is
  `component-parity`'s job, run file-pair by file-pair.
- It did not check translation string completeness inside `po/` — that is
  `translation-parity`'s job.
- It did not run or screenshot the app.

## Bottom line

No missing component files were found. The next useful step for this fork is
not "create missing lib files" (there are none) but a `component-parity` pass
per file pair to confirm each `lib/*.rb` actually reproduces every widget,
CSS class, signal and action its upstream file(s) declare — the file existing
is necessary but not sufficient for parity.
