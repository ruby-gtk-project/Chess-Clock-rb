# Component identification — Chess Clock

| | |
|---|---|
| Upstream | `origin/main` @ `775f046` (2026-09-20), Python 3 + PyGObject, GTK 4 / libadwaita 1.4 |
| Port | `ruby` @ `68fd69d` (unchanged since `5457099`: this round's commit touched `application.rb`, `timer_button.rb`, `about_dialog.rb` and added `COPYING`/`CONTRIBUTING.md`, none of which change the widget/CSS/signal/action inventory below) |
| Scope | whole app |
| Tooling | `component-identification/scripts/component-scan.sh` over both trees; every row then read in the file |
| Environment | `nix develop`, GTK 4.22.4, ruby 3.4.9, `xvfb-run -a` |

Upstream splits almost every component across a `.py` subclass and its `.ui`
template, so the component is the **pair**, and the rows of every upstream file
on the left of an arrow are unioned before anything is compared. The port has
no `.ui` files except one heredoc (`shortcuts_window.rb`), which carries
upstream's `help-overlay.ui` verbatim because `GtkShortcutsWindow` takes its
sections only through GtkBuildable.

## Step 1 — the declarative UI

Upstream has four `.ui` files and one of them holds two roots:

```
src/gtk/window.ui             <template class="ChessClockWindow" parent="AdwApplicationWindow">
                              <menu id="primary_menu">          (3 sections, 5 items)
src/gtk/timerbutton.ui        <template class="ChessClockTimerButton" parent="GtkButton">
src/gtk/timecontrolentry.ui   <template class="ChessClockTimeControlEntry" parent="GtkBox">
src/gtk/help-overlay.ui       <object class="GtkShortcutsWindow" id="help_overlay">   (no backing .py)
```

Three app-defined template classes are instantiated from `window.ui`
(`ChessClockTimeControlEntry`, two `ChessClockTimerButton`s), so the hierarchy
is real and the port has to reproduce it: it does, as
`TimeControlEntry#build` and two `TimerButton`s.

## Unit map

| Upstream | Port |
|---|---|
| `src/main.py` (`ChessClockApplication`) | `lib/chess_clock/application.rb` |
| `src/main.py` (`on_about_action`) + `data/…metainfo.xml.in` | `lib/chess_clock/about_dialog.rb` |
| `src/window.py` + `src/gtk/window.ui` (`<template>`) | `lib/chess_clock/window.rb` |
| `src/gtk/window.ui` (`<menu id="primary_menu">`) | `lib/chess_clock/primary_menu.rb` |
| `src/gtk/help-overlay.ui` | `lib/chess_clock/shortcuts_window.rb` |
| `src/timerbutton.py` + `src/gtk/timerbutton.ui` | `lib/chess_clock/timer_button.rb` |
| `src/timecontrolentry.py` + `src/gtk/timecontrolentry.ui` | `lib/chess_clock/time_control_entry.rb` |
| `src/timer.py` | `lib/chess_clock/timer.rb` |
| `src/statemachine.py` (`MachineState` + base) | `lib/chess_clock/state_machine.rb` |
| `src/statemachine.py` (3 subclasses) | `increment_state_machine.rb`, `bronstein_state_machine.rb`, `delay_state_machine.rb` |
| `src/statemachine.py` (`GSound.Context`) | `lib/chess_clock/alert_sound.rb` |
| `src/gtk/style.css` + `src/gtk/style-hc.css` | `lib/chess_clock/style.rb` (two heredocs) |
| `data/…gschema.xml` | `lib/chess_clock/settings.rb` (GSettings, file fallback) |
| GObject signal plumbing in `timer.py` / `statemachine.py` | `lib/chess_clock/signals.rb` |
| `src/gtk/window.ui` `<accessibility>` + `timerbutton.py` `update_property` | `lib/chess_clock/accessible_label.rb` |
| `src/chess-clock.in` (`bindtextdomain`) | `lib/chess_clock/translation.rb` |
| `src/chess-clock.in` | `exe/chess-clock` |
| `data/…desktop.in`, `…metainfo.xml.in`, `…service.in`, `…gschema.xml`, `data/icons/**` (4), `data/screenshots/**` (3) | the same paths — **verified byte-identical, 11/11** |
| `po/*.po` (42) + `po/LINGUAS` | the same paths — **verified byte-identical** |
| `po/POTFILES.in` | retargeted at `lib/` and `data/` |
| **`src/chess-clock.gresource.xml`** | **nothing** |
| **`meson.build`, `src/meson.build`, `data/meson.build`, `data/icons/meson.build`, `po/meson.build`** | `Rakefile` tasks `locale`, `gschema`, `install:data` — partial |
| **`COPYING`** | **nothing** |
| **`CONTRIBUTING.md`** | **nothing** |
| **`chess-clock.doap`** | **nothing** |
| **`eu.fortysixandtwo.chessclock.json`** (Flatpak) | **nothing** |

Eighteen Ruby units, listed in the order a user meets them below.

## Step 3/4 — scan totals, after reading every row

```
component-scan.sh <upstream>  → 103 rows
component-scan.sh <port>      → 101 rows
```

| Axis | Upstream distinct | Port distinct | In upstream, not in port |
|---|---:|---:|---|
| Widget types | 24 | 25 | **0** |
| CSS classes | 20 | 20 | **0** — the sets are identical |
| `css-name` | 1 (`button`) | 0 | `button`, set by `set_css_name` in `timerbutton.py:54` |
| Signals | 16 | 13 | none by *set* once factories and loops are resolved |
| Actions | 7 literal | 1 literal | none — the port builds all seven from `ACCELERATORS` hashes |

The signal and action streams differ only because the port installs its actions
from two hashes (`Application::ACCELERATORS`, `Window::ACCELERATORS`) and
connects buttons in loops, which is exactly the repeater case the skill warns
about. Read off the install sites, the action sets are equal:
`app.quit`, `app.about`, `win.new`, `win.restart`, `win.close`, `win.menu`,
`win.muted`, plus `win.show-help-overlay` which libadwaita installs for
upstream and `window.rb:78` installs by hand here.

Widget-count differences, all resolved by reading:

| Type | Up | Port | Reading |
|---|---:|---:|---|
| `Adw.ApplicationWindow` | 2 | 1 | the template root counted twice upstream (`window.py` class + `window.ui` template); strike one → 1 = 1 |
| `Gtk.Box` | 8 | 7 | the `TimeControlEntry` template root is itself a `GtkBox`, counted in both upstream files → 7 = 7 |
| `Gtk.Button` | 12 | 4 | 8 of upstream's are the presets; the port builds them from one `preset_button` factory over `PRESETS` — a repeater, 8 at runtime |
| `Gtk.SpinButton` | 3 | 1 | one `spin_button` factory, 3 call sites |
| `Gtk.WindowControls` | 3 | 2 | one `window_controls(side)` factory, 3 call sites |
| `Gtk.Label` | 7 | 8 | 7 = 7, plus the never-parented `Gtk::Label` that `AccessibleLabel#announce` uses as a LABELLED_BY carrier — an explained extra |
| `Gtk.ShortcutsShortcut` | 6 | 7 | 6 in the heredoc; the 7th row is the `grep Gtk::ShortcutsShortcut` line in `shortcuts_window.rb:140` — a scan artefact |
| `Adw.AboutWindow` | 1 | 2 | both port rows are in a comment; the widget is `Adwaita::AboutDialog` (substitution, recorded in parity) |

## The inventory, in the order a user meets it

### `lib/chess_clock/application.rb` — the application singleton

| Widget / object | × | CSS | Signals / actions | Notes |
|---|---:|---|---|---|
| `Gtk::Application` | 1 | — | `activate`; installs `app.quit` (`<primary>q`), `app.about` | upstream is an `Adw.Application`; `Adwaita.init` stands in |

Repeaters: the two actions, from `ACCELERATORS`. Conditional: `present:` gates
`win.present` for the drivers.

### `lib/chess_clock/window.rb` — the window and its two screens

Setup screen (stack page `setup`):

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk::Stack` | 1 | — | — | `slide_left_right` |
| `Gtk::WindowHandle` | 1 | — | — | a11y name `p_("a11y", "Select time controls")` |
| `Adwaita::ToolbarView` | 1 | — | — | |
| `Adwaita::HeaderBar` | 1 | — | — | the setup header |
| `Gtk::ScrolledWindow` | 1 | — | — | `hscrollbar_policy = :never` |
| `Gtk::Box` | 2 | — | — | setup box (24), welcome box (12) |
| `Gtk::Label` | 2 | `title-1` (1st) | — | `_("Welcome to Chess Clock")`, `_("Select time controls below to get started")` |
| `Adwaita::PreferencesGroup` | 1 | — | — | |
| `Adwaita::PreferencesRow` | 1 | — | — | `activatable = false` |
| `Adwaita::ComboRow` | 1 | — | `notify::selected` → `control-method` | `_("Time control method")`, 3-item `Gtk::StringList` |
| `Gtk::Button` | 1 | `pill`, `suggested-action` | `clicked` → `on_start_game` | `_("Start Game")` |

Timer screen (stack page `timer`):

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk::Overlay` | 1 | — | — | 6 overlays over the faces |
| `Gtk::Box` | 2 | `linked` (timer box) | — | timer box (homogeneous), headerbar box |
| `Gtk::Revealer` | 1 | — | — | `crossfade`, `overflow = :visible` |
| `Adwaita::HeaderBar` | 1 | `transparent` | — | |
| `Gtk::EventControllerMotion` | 1 (controller) | — | `enter`, `motion`, `leave` | on the revealer, as upstream |
| `Gtk::WindowControls` | 3 | `white` ×2, `black` ×1 — swapped by `awbb`/`abbw` | — | start, start-end (hidden), end |
| `Gtk::MenuButton` | 1 | `image-button`, `circular`, `osd` | `menu_model` = `PrimaryMenu` | `_("Main Menu")` |
| `Gtk::Button` | 1 | `image-button`, `circular`, `osd`, `large` | `clicked` → `on_pause_clicked` | `_("Toggle Pause")`; icon swaps start/pause |
| `Adwaita::Breakpoint` | 1 | — | `apply`, `unapply` | `max-aspect-ratio: 1/1 or max-width: 520px` |

Actions: `win.new` (`<primary>n`), `win.restart` (`<primary>r`),
`win.close` (`<primary>w`), `win.menu` (`F10`),
`win.show-help-overlay` (`<primary>question`), `win.muted` (stateful boolean).

Repeaters: five actions from `ACCELERATORS`; three window-controls from one
factory. Conditional: the whole narrow layout, behind the breakpoint.
Dynamic CSS: `white`/`black` on all three window-controls.

### `lib/chess_clock/timer_button.rb` — one player's clock face

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk::Button` (subclass) | 1 | `timerbutton`, `opaque`, `white`\|`black`, `running`, `expired`, `inverted` | `clicked` (by the machine) | a11y name swaps with the colour |
| `Adwaita::BreakpointBin` | 1 | — | — | 240×130 request |
| `Adwaita::Breakpoint` | 1 | — | `apply`, `unapply` | `min-width: 600px` → 100pt `Pango::AttrSize` |
| `Gtk::Box` | 1 | — | — | forced `TextDirection::LTR` |
| `Gtk::Label` | 3 | `colon` (middle) | — | minutes, `∶`, seconds |

Dynamic CSS, every value: `white`, `black`, `running`, `expired`, `inverted`.
Not set: `css-name` (`button`) and `Gtk::AccessibleRole::BUTTON`, both of which
`timerbutton.py:53-55` sets.

### `lib/chess_clock/time_control_entry.rb` — the time-control picker

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk::Box` | 2 | — | — | container (6, margins 6), custom-control box (LTR) |
| `Gtk::Grid` | 1 | — | — | 4×2, column-homogeneous, spacing 6 |
| `Gtk::Button` | 8 | `time-button` | `clicked` → `set_control` | repeater over `PRESETS`; 8 translated tooltips |
| `Gtk::SpinButton` | 3 | `custom-spin` | `wrapped`, `output` (seconds only) | vertical; `_("Main time minutes"/"seconds"/"Increment seconds")` |
| `Gtk::Label` | 2 | `custom-label` | — | `∶`, `+` |
| `Gtk::Adjustment` | 3 (type) | — | `value-changed` → GSettings | upper 999 / 59 / 999 |

### `lib/chess_clock/primary_menu.rb` — the menu behind the circular button

Three `Gio::Menu` sections, five items, mnemonics intact:
`_("_New Time Control")` → `win.new`, `_("_Restart Timer")` → `win.restart`;
`_("_Mute Alert Sound")` → `win.muted`; `_("_Keyboard Shortcuts")` →
`win.show-help-overlay`, `_("_About Chess Clock")` → `app.about`.

### `lib/chess_clock/shortcuts_window.rb` — the shortcuts window

| Widget | × | Notes |
|---|---:|---|
| `Gtk::ShortcutsWindow` | 1 | `modal`, from a GtkBuilder string |
| `Gtk::ShortcutsSection` | 1 | `section-name shortcuts`, `max-height 10` |
| `Gtk::ShortcutsGroup` | 2 | `p_("shortcut window", "Game"/"General")` |
| `Gtk::ShortcutsShortcut` | 6 | `win.new`, `win.restart`, `win.menu`, `win.show-help-overlay`, `win.close`, `app.quit` |

`#resolve_accelerators` does the `action-name` → key-combination lookup GTK's
`root` vfunc would have done, because by the time Ruby holds the window that
vfunc has already run with no application reachable.

### `lib/chess_clock/about_dialog.rb` — the About window

`Adwaita::AboutDialog` ×1, with name, icon, developer name, version, comments,
website, issue URL, copyright, licence, 4 developers, 1 artist, translator
credits, release notes, and two `add_link` rows (`Translate`, `Contribute`).
Upstream builds an `Adw.AboutWindow` from the appdata instead.

### Non-widget units

`timer.rb` (3 signals: `changed`, `expired`, `alerted`),
`state_machine.rb` + three subclasses (5 states, 5 signals: `a_active`,
`b_active`, `pause`, `awbb`, `abbw`), `signals.rb` (the connect/emit/disconnect
stand-in), `alert_sound.rb` (GSound through `GObjectIntrospection::Loader`),
`settings.rb` (8 keys, `SchemaStore` or `FileStore`), `style.rb` (two
providers, high-contrast watcher), `translation.rb` (textdomain `chess-clock`),
`accessible_label.rb` (LABELLED_BY carriers), `exe/chess-clock`.

## Repeaters and conditionals, collected

- 8 preset buttons from `PRESETS` (`time_control_entry.rb:53`).
- 3 spin buttons from `spin_button` (`time_control_entry.rb:204`).
- 3 window-controls from `window_controls(side)` (`window.rb:546`).
- 2 clock faces from `TimerButton.new(:white|:black)`.
- 5 window actions + 2 app actions from `ACCELERATORS` hashes.
- 5 menu items from `PrimaryMenu::SECTIONS`.
- 8 shortcut titles from `ShortcutsWindow.title` — and so invisible to any
  extractor; see `translation-parity.md` **T2**.
- Conditional: the entire narrow layout; the 100pt face; the high-contrast
  stylesheet; `AlertSound`'s three routes.

## Where the inventory is thin, and it is not the port's fault

`Adwaita::Breakpoint` setters carrying Pango attribute strings
(`0 -1 size 102400`) are GtkBuilder-only syntax, so upstream's declarative
font-size jump has no setter equivalent; the port reproduces it with
`apply`/`unapply` handlers building a real `Pango::AttrList`. Recorded as a
correspondence in `component-parity.md`, not a gap.
