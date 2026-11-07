# Component identification — Chess Clock

| | |
|---|---|
| Upstream | `origin/main` @ `775f046` |
| Port | `ruby` @ `28007cd` |
| Scope | whole app |
| Tooling | `component-identification/scripts/component-scan.sh` over an `origin/main` export and the working tree, every raw-count difference then resolved by reading the files |
| Environment | `nix develop`, GTK 4.22.4, ruby 3.4.9, `xvfb-run -a` |

Upstream splits almost every component across a `.py` subclass and its `.ui`
template, so the component is the **pair**. The port has no `.ui` files
except one heredoc (`shortcuts_window.rb`), which carries upstream's
`help-overlay.ui` verbatim because `GtkShortcutsWindow` takes its sections
only through GtkBuildable.

## Unit map — 18 Ruby units

| Upstream | Port |
|---|---|
| `src/main.py` (`ChessClockApplication`) | `lib/chess_clock/application.rb` |
| `src/main.py` (`on_about_action`) + `data/…metainfo.xml.in` | `lib/chess_clock/about_dialog.rb` |
| `src/window.py` + `src/gtk/window.ui` | `lib/chess_clock/window.rb` |
| `src/gtk/window.ui` (`<menu id="primary_menu">`) | `lib/chess_clock/primary_menu.rb` |
| `src/gtk/help-overlay.ui` | `lib/chess_clock/shortcuts_window.rb` |
| `src/timerbutton.py` + `src/gtk/timerbutton.ui` | `lib/chess_clock/timer_button.rb` |
| `src/timecontrolentry.py` + `src/gtk/timecontrolentry.ui` | `lib/chess_clock/time_control_entry.rb` |
| `src/timer.py` | `lib/chess_clock/timer.rb` |
| `src/statemachine.py` (`MachineState` + base) | `lib/chess_clock/state_machine.rb` |
| `src/statemachine.py` (3 subclasses) | `increment_state_machine.rb`, `bronstein_state_machine.rb`, `delay_state_machine.rb` |
| `src/statemachine.py` (`GSound.Context`) | `lib/chess_clock/alert_sound.rb` |
| `src/gtk/style.css` + `src/gtk/style-hc.css` | `lib/chess_clock/style.rb` |
| `data/…gschema.xml` | `lib/chess_clock/settings.rb` |
| GObject signal plumbing in `timer.py` / `statemachine.py` | `lib/chess_clock/signals.rb` |
| `src/gtk/window.ui` `<accessibility>` + `timerbutton.py` `update_property` | `lib/chess_clock/accessible_label.rb` |
| `src/chess-clock.in` (`bindtextdomain`) | `lib/chess_clock/translation.rb` |
| `src/chess-clock.in` | `exe/chess-clock` |
| `data/…desktop.in`, `…metainfo.xml.in`, `…service.in`, `…gschema.xml`, `data/icons/**` (4), `data/screenshots/**` (3) | same paths — **byte-identical, re-diffed this round, 11/11** |
| `po/*.po` (42) + `po/LINGUAS` | same paths — **byte-identical, re-diffed this round, 42/42** |
| `po/POTFILES.in` | retargeted at `lib/` and `data/`; `rake pot` regenerates from it |
| `chess-clock.doap` | `chess-clock.doap` — **byte-identical, re-diffed this round** |
| `eu.fortysixandtwo.chessclock.json` | `eu.fortysixandtwo.chessclock.json` — **byte-identical, re-diffed this round** |
| `COPYING` | `COPYING` — byte-identical |
| `CONTRIBUTING.md` | `CONTRIBUTING.md` — byte-identical |
| **`src/chess-clock.gresource.xml`** | **nothing** |
| **`meson.build`, `src/meson.build`, `data/meson.build`, `data/icons/meson.build`, `po/meson.build`** | `Rakefile` tasks `locale`, `pot`, `gschema`, `install:data` — partial (no validation task; see component-parity **G10**) |

## Scan totals

```
component-scan.sh <origin/main export>  → 103 rows
component-scan.sh <working tree>        → 101 rows
```

| Axis | Upstream distinct | Port distinct | In upstream, not in port |
|---|---:|---:|---|
| Widget types | 24 | 25 | **0** |
| CSS classes | 20 | 20 | **0** — identical sets |
| `css-name` | 1 (`button`) | 0 raw hits | 0 real — inherited from `Gtk::Button`, see below |
| Signals | 16 | 13 | none by *set* once factories/loops are resolved |
| Actions | 7 literal | 1 literal | none — the port builds all 7 from `ACCELERATORS` hashes |

### Count differences, all resolved by reading

| Type | Up | Port | Reading |
|---|---:|---:|---|
| `Adw.ApplicationWindow` | 2 | 1 | upstream double-counts the template root (`window.py` subclass line + `window.ui`'s `<template parent>`) — 1 = 1 |
| `Gtk.Box` | 8 | 7 | `TimeControlEntry`'s template root is itself a `GtkBox`, counted once in the `.ui` and again as the `.py` subclass line — 7 = 7 |
| `Gtk.Button` | 12 | 5 raw rows | 8 of upstream's are the presets; `time_control_entry.rb#preset_button` is one factory called 8 times over `PRESETS` — 8 at runtime, 12 = 12 |
| `Gtk.SpinButton` | 3 | 1 raw row | one `spin_button` factory, three memoized call sites (`minutes`, `seconds`, `increment`) — 3 = 3 |
| `Gtk.WindowControls` | 3 | 2 raw rows | one `window_controls(side)` factory, three memoized call sites, three separate overlays added at `window.rb:136-138` — 3 = 3 |
| `Gtk.ShortcutsShortcut` | 6 | 7 raw rows | the port's extra row is a `grep`-matching comment/method body in `shortcuts_window.rb`, not a 7th shortcut; the heredoc has exactly 6 — 6 = 6 |
| `Adw.AboutWindow` | 1 | 2 raw rows | both port rows are in a comment; the real widget is `Adwaita::AboutDialog` — a recorded substitution (component-parity **G7**), not a count mismatch |
| `css-name` (`button`) | 1 | 0 | `timerbutton.py:54` sets it explicitly; `TimerButton < Gtk::Button` inherits the name and the `BUTTON` accessible role for free, so the port never has a literal call site to scan for — verified live (`TimerButton.new.css_name == "button"`) |

## The inventory, by file a user meets in order

### `application.rb` — the application singleton

`Gtk::Application` ×1, installs `app.quit` (`<primary>q`), `app.about`.
Upstream is `Adw.Application`; `Adwaita.init` stands in (component-parity
**G3**).

### `window.rb` — the window and its two screens

Setup screen: `Gtk::Stack`, `Gtk::WindowHandle`, `Adwaita::ToolbarView`,
`Adwaita::HeaderBar`, `Gtk::ScrolledWindow`, 2 `Gtk::Box`, 2 `Gtk::Label`
(1 with `title-1`), `Adwaita::PreferencesGroup`/`Row`, `Adwaita::ComboRow`,
1 `Gtk::Button` (`pill`, `suggested-action`).

Timer screen: `Gtk::Overlay` (6 children), 2 `Gtk::Box` (1 `linked`),
`Gtk::Revealer`, `Adwaita::HeaderBar` (`transparent`),
`Gtk::EventControllerMotion`, 3 `Gtk::WindowControls` (`white`/`black`,
swapped on `awbb`/`abbw`), `Gtk::MenuButton` (`image-button`, `circular`,
`osd`), 1 `Gtk::Button` (play/pause, + `large`), `Adwaita::Breakpoint`.

Actions: `win.new`, `win.restart`, `win.close`, `win.menu`,
`win.show-help-overlay`, `win.muted` (stateful boolean).

### `timer_button.rb` — one player's clock face

`Gtk::Button` subclass ×1 (`timerbutton`, `opaque`, `white`|`black`,
`running`, `expired`, `inverted`), `Adwaita::BreakpointBin`,
`Adwaita::Breakpoint` (`min-width: 600px` → 100pt via a real
`Pango::AttrList`), `Gtk::Box` (forced LTR), 3 `Gtk::Label` (`colon`).

### `time_control_entry.rb` — the time-control picker

2 `Gtk::Box`, `Gtk::Grid` (4×2), 8 `Gtk::Button` (`time-button`, repeater
over `PRESETS`), 3 `Gtk::SpinButton` (`custom-spin`), 2 `Gtk::Label`
(`custom-label`), 3 `Gtk::Adjustment`.

### `primary_menu.rb` — 3 sections, 5 items, mnemonics intact

### `shortcuts_window.rb` — `Gtk::ShortcutsWindow`, 1 section, 2 groups, 6 shortcuts

### `about_dialog.rb` — `Adwaita::AboutDialog` (substitution for `Adw.AboutWindow`, **G7**)

### Non-widget units

`timer.rb` (3 signals), `state_machine.rb` + 3 subclasses (5 states, 5
signals), `signals.rb` (connect/emit/disconnect mixin), `alert_sound.rb`
(GSound via `GObjectIntrospection::Loader`), `settings.rb` (8 keys,
`SchemaStore`/`FileStore`), `style.rb` (2 stylesheets, high-contrast
watcher), `translation.rb` (textdomain `chess-clock`), `accessible_label.rb`
(LABELLED_BY carriers), `exe/chess-clock`.

## Repeaters and conditionals, collected

8 preset buttons from `PRESETS`; 3 spin buttons from `spin_button`; 3
window-controls from `window_controls(side)`; 2 clock faces from
`TimerButton.new(:white|:black)`; 5 window + 2 app actions from
`ACCELERATORS` hashes; 5 menu items from `PrimaryMenu::SECTIONS`; 8 shortcut
titles from `ShortcutsWindow.title`. Conditional: the whole narrow layout;
the 100pt face; the high-contrast stylesheet; `AlertSound`'s three routes.

## Where the inventory is thin, and it is not the port's fault

`Adwaita::Breakpoint` setters carrying Pango attribute strings
(`0 -1 size 102400`) are GtkBuilder-only syntax; the port reproduces the
effect with `apply`/`unapply` handlers building a real `Pango::AttrList`.
Recorded as a correspondence in `component-parity.md`, not a gap.

## What this does not settle

Identification alone does not establish behavioural parity — see
`.reports/component-parity.md` for the four genuinely open gaps (**G3**,
**G4**, **G5**, **G10**) that a type/CSS/signal scan cannot surface by
construction, because the port *has* the widget and the class; what it
lacks is a GResource, bindable GObject properties on two classes, an
audible alert, and build-time metadata validation.

**Correction to the previous working-tree draft of this file**: an earlier,
never-committed edit of this document (visible in `git diff` before this
round) cited the port at `e25a1b2`, one commit behind `28007cd`
("Add DOAP and Flatpak manifest, closing G9"), and so never reflects that
`chess-clock.doap` and `eu.fortysixandtwo.chessclock.json` exist in the tree.
That draft is superseded by this document. See
`.reports/accountability-ensurance.md` for why a stale draft sitting in the
working tree is treated as a finding in its own right.
