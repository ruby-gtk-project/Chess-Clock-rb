# Component identification — Chess Clock, port side

| | |
|---|---|
| Upstream | `origin/main` @ `775f046` (Python 3 + PyGObject, GTK 4 / libadwaita 1.4) |
| Port | `ruby` @ `270aa8a` |
| Scope | whole app (12 units) |
| Scans | `component-scan.sh` over both trees, symbol table of 1301 GIR symbols |

The upstream inventory is `.reports/component-inventory.md` and is not repeated
here. This document is the **port-side** inventory plus the unit map, which is
what `component-parity.md` joins on.

## Unit map

Upstream splits almost every component across a `.py` subclass and its `.ui`
template. The component is the pair, so the rows of both are unioned before any
comparison.

| Upstream | Port |
|---|---|
| `src/main.py` | `lib/chess_clock/application.rb` |
| `src/main.py` (`on_about_action`) + `data/eu.fortysixandtwo.chessclock.metainfo.xml.in` | `lib/chess_clock/about_dialog.rb` |
| `src/window.py` + `src/gtk/window.ui` (`<template>`) | `lib/chess_clock/window.rb` |
| `src/gtk/window.ui` (`<menu id="primary_menu">`) | `lib/chess_clock/primary_menu.rb` |
| `src/gtk/help-overlay.ui` | `lib/chess_clock/shortcuts_window.rb` |
| `src/timerbutton.py` + `src/gtk/timerbutton.ui` | `lib/chess_clock/timer_button.rb` |
| `src/timecontrolentry.py` + `src/gtk/timecontrolentry.ui` | `lib/chess_clock/time_control_entry.rb` |
| `src/timer.py` | `lib/chess_clock/timer.rb` |
| `src/statemachine.py` (`MachineState`, base class) | `lib/chess_clock/state_machine.rb` |
| `src/statemachine.py` (3 subclasses) | `increment_state_machine.rb`, `bronstein_state_machine.rb`, `delay_state_machine.rb` |
| `src/statemachine.py` (`GSound.Context`) | `lib/chess_clock/alert_sound.rb` |
| `src/gtk/style.css` + `src/gtk/style-hc.css` | `lib/chess_clock/style.rb` (heredocs) |
| `data/eu.fortysixandtwo.chessclock.gschema.xml` | `lib/chess_clock/settings.rb` (JSON shim) |
| GObject signal plumbing in `timer.py` / `statemachine.py` | `lib/chess_clock/signals.rb` |
| `src/chess-clock.in` | `exe/chess-clock` |
| **`data/eu.fortysixandtwo.chessclock.desktop.in`** | **nothing** |
| **`data/eu.fortysixandtwo.chessclock.metainfo.xml.in`** | **nothing** |
| **`data/eu.fortysixandtwo.chessclock.service.in`** | **nothing** |
| **`data/icons/**` (4 SVGs)** | **nothing** |
| **`src/chess-clock.gresource.xml`** | n/a — the port builds in Ruby, by design of the house style |
| **`po/` (42 `.po`, `LINGUAS`, `POTFILES.in`)** | **nothing** |

Six upstream files on the left of an arrow have nothing opposite them. That is
the first and largest class of gap and it is found here, not in any diff.

## Whole-app scan totals

Counts exclude `.claude/`. Only the `widget` stream's counts are per-instance;
`css`, `signal` and `action` counts are attachment sites in the text, so the
port's loops and factories legitimately read lower.

| Stream | Upstream rows | Port rows | Distinct upstream | Distinct port |
|---|---:|---:|---:|---:|
| `widget` | 33 | 31 | 24 | 24 |
| `controller` | 1 | 1 | 1 | 1 |
| `type` | 11 | 20 | — | — |
| `css` | 24 | 22 | 20 | 20 |
| `css-name` | 1 | 0 | 1 | 0 |
| `signal` | 21 | 19 | 15 | 15 |
| `action` | 12 | 7 | 12 | 7 |

The port's distinct widget-type and CSS-class sets equal upstream's, which is
the shape of a UI that was laid out from the inventory rather than guessed. The
`action` stream is the one that reads short, and per the skill it is also the
least trustworthy — read against the install sites, all five window actions and
both application actions are present (below).

## Port inventory, in the order a user meets the app

### `lib/chess_clock/application.rb` — the application singleton

| Widget / item | × | CSS | Signals / actions | Notes |
|---|---:|---|---|---|
| `Gtk::Application` | 1 | — | `activate` | app id **`org.rubygtkproject.ChessClock`**, `:default_flags`. `Adwaita::Application` is unusable from Ruby, so the app object is Gtk and `Adwaita.init` is called by hand |
| action `app.quit` | 1 | — | `<primary>q` | built in a loop over `ACCELERATORS`, so the name is a variable and the scan cannot see it |
| action `app.about` | 1 | — | no accel | opens `AboutDialog` |
| `Style#load` | — | — | — | installs the two stylesheets on the default display at `activate`; upstream gets this free from `AdwApplication` |

Repeaters: the two actions, from `ACCELERATORS`. Conditional: `@present`
suppresses `window.present`, a test seam with no upstream counterpart.

### `lib/chess_clock/about_dialog.rb` — the About window

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Adwaita::AboutDialog` | 1 | — | — | upstream builds an `Adw.AboutWindow` with `new_from_appdata`; `AboutDialog` is the newer equivalent. Fields set by hand: name, icon, developer name, version `0.6.2`, comments, website, issue url, copyright, GPL-3.0, 4 developers, 1 artist, `translator-credits` |

### `lib/chess_clock/window.rb` — the application window

| Widget | × | CSS | Signals / actions | Notes |
|---|---:|---|---|---|
| `Adwaita::ApplicationWindow` | 1 | — | actions `win.new` `<primary>n`, `win.restart` `<primary>r`, `win.close` `<primary>w`, `win.menu` `F10`, `win.show-help-overlay` `<primary>question`, stateful `win.muted` | title, 360×294 size request, geometry restored from `Settings#apply_to` |
| `Gtk::Stack` | 1 | — | — | `:slide_left_right`; pages named `setup` / `timer` |
| `Adwaita::Breakpoint` | 1 | — | `apply`, `unapply` | `max-aspect-ratio: 1/1 or max-width: 520px`; the eight upstream setters are run imperatively in `apply_narrow` / `unapply_narrow` |
| `Gtk::WindowHandle` | 1 | — | — | a11y label "Select time controls" via `update_property` |
| `Adwaita::ToolbarView` + `Adwaita::HeaderBar` | 1 + 1 | — | — | setup header |
| `Gtk::ScrolledWindow` | 1 | — | — | `hscrollbar_policy = :never`; `win.new` zeroes its vadjustment |
| `Gtk::Box` | 3 | — | — | setup page box (24, margins 42/36/12/12), welcome box (12), headerbar box |
| `Gtk::Label` | 2 | `title-1` (1st) | — | "Welcome to Chess Clock", "Select time controls below to get started" |
| `Adwaita::PreferencesGroup` | 1 | — | — | |
| `Adwaita::PreferencesRow` | 1 | — | — | `activatable = false`; hosts `TimeControlEntry#build` |
| `Adwaita::ComboRow` | 1 | — | `notify::selected` → `Settings#bind_combo_row` | `Gtk::StringList` of 3 |
| `Gtk::Button` (start) | 1 | `pill`, `suggested-action` | `clicked` → `on_start_game` | |
| `Gtk::Overlay` | 1 | — | — | timer box as child, six overlays |
| `Gtk::Revealer` | 1 | — | — | crossfade, `overflow = :visible`, revealed at build |
| `Adwaita::HeaderBar` (timer) | 1 | `transparent` | — | `opacity: 0` — exists for the drag area and nothing else |
| `Gtk::EventControllerMotion` | 1 (controller) | — | `enter`, `motion` → `reveal_headerbar`; `leave` → `hide_headerbar` | added to the revealer |
| `Gtk::WindowControls` | 3 | `white` / `white` / `black`, repainted per side by `paint_controls` | — | built by the private `window_controls(side)` factory — one textual occurrence, three widgets |
| `Gtk::MenuButton` | 1 | `image-button`, `circular`, `osd` | menu model `PrimaryMenu#build`; `win.menu` pops it up on the timer page | `open-menu-symbolic`, tooltip "Main Menu" |
| `Gtk::Button` (play/pause) | 1 | `image-button`, `circular`, `large`, `osd` | `clicked` → `state_machine.on_pause_clicked` | icon swapped by `on_pause` |
| `Gtk::Box` (timer box) | 1 | `linked` | — | homogeneous; `:vertical` at the breakpoint |
| `TimerButton` | 2 | `white` (a), `black` (b) | see below | |

Repeaters: `ACCELERATORS` (5 actions), `window_controls` (3 instances),
`paint_controls` (one helper for six upstream `add_css_class` sites).
Conditional: every `apply_narrow` / `unapply_narrow` property.

### `lib/chess_clock/primary_menu.rb` — the menu behind the circular button

Three sections, five items, no widgets: `Gio::Menu` + three
`append_section`. Items `_New Time Control` → `win.new`, `_Restart Timer` →
`win.restart`, `_Mute Alert Sound` → `win.muted`, `_Keyboard Shortcuts` →
`win.show-help-overlay`, `_About Chess Clock` → `app.about`. Repeater:
`SECTIONS`, so none of the five labels or actions reaches the scan.

### `lib/chess_clock/shortcuts_window.rb` — the shortcuts window

`Gtk::ShortcutsWindow` from a `Gtk::Builder` string — the one place the port
keeps a declarative description, because `GtkShortcutsWindow` takes its
sections only through `GtkBuildable.add_child`. 1 section (`max-height: 10`),
2 `GtkShortcutsGroup`, 6 `GtkShortcutsShortcut`, each naming an action rather
than an accelerator. The XML carries `translatable="yes"
context="shortcut window"` on all 8 titles.

### `lib/chess_clock/timer_button.rb` — one player's clock face

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `TimerButton < Gtk::Button` | 1 | `timerbutton`, `opaque`, plus `white`/`black`, `running`, `expired`, `inverted` set dynamically | handlers `on_changed`, `on_white`, `on_black`, `on_active`; `clicked` connected by the state machine | `Gtk::BinLayout`, `hexpand`, a11y label set in the constructor and again on every colour swap |
| `Adwaita::BreakpointBin` | 1 | — | — | 240×130 request |
| `Adwaita::Breakpoint` | 1 | — | `apply`, `unapply` | `min-width: 600px` → a `Pango::AttrList` with `AttrSize(100 × Pango::SCALE)` on all three labels, and an empty list on unapply |
| `Gtk::Box` | 1 | — | — | forced `Gtk::TextDirection::LTR` |
| `Gtk::Label` | 3 | `colon` (middle) | — | minutes, `∶`, seconds (`%02d`), time ceil'd from microseconds |

`inverted` is a plain Ruby attribute, not a GObject property.

### `lib/chess_clock/time_control_entry.rb` — the time-control picker

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk::Box` (container) | 1 | — | — | vertical, 6, margins 6 |
| `Gtk::Grid` | 1 | — | — | 4×2, homogeneous columns, spacing 6 |
| `Gtk::Button` | 8 | `time-button` | `clicked` → `set_control(preset)` | built from `PRESETS`; one scan row, eight widgets |
| `Gtk::Box` (custom) | 1 | — | — | forced LTR |
| `Gtk::SpinButton` | 3 | `custom-spin` | seconds: `wrapped`, `output` | built by the private `spin_button` factory; each backed by a `Gtk::Adjustment` bound through `Settings#bind_adjustment` |
| `Gtk::Label` | 2 | `custom-label` | — | `∶`, `+`, from the `custom_label` factory |

Repeaters: `PRESETS` (8 buttons, 8 tooltips, 8 `time-button` attachments),
`spin_button` (3), `custom_label` (2).

### Models — no widgets

| File | What it is |
|---|---|
| `timer.rb` | one countdown; `changed`/`expired`/`alerted`; `Process.clock_gettime(CLOCK_MONOTONIC)`; installs its own `add_tick_callback` on the machine's window when it starts running |
| `state_machine.rb` | five states, five signals, button wiring, `Gtk::ApplicationInhibitFlags::IDLE` inhibit |
| `increment_state_machine.rb` / `bronstein_state_machine.rb` / `delay_state_machine.rb` | the three time-control rules |
| `alert_sound.rb` | spawns `canberra-gtk-play --id dialog-warning --volume 1`, falling back to `Gdk::Display#beep` |
| `signals.rb` | a hand-rolled `connect`/`disconnect`/`emit` with integer ids, in place of GObject signals |
| `settings.rb` | the eight gschema keys, backed by JSON under `XDG_CONFIG_HOME` |
| `style.rb` | the two stylesheets as heredocs, installed via `Gtk::CssProvider`, high-contrast switched off `Adwaita::StyleManager` |

### Stylesheet

Extracted from the two heredocs and diffed against
`src/gtk/style.css` and `src/gtk/style-hc.css`: **byte-identical, both files**.
So every app-namespaced class has its rule; the CSS question collapses to
attachment, which is answered in `component-parity.md`.

## Items the scan could not see, recorded by reading

- All five `win.*` actions and both `app.*` actions: names come from the
  `ACCELERATORS` hashes, so they are built from variables.
- The five menu labels and action names: from `SECTIONS`.
- Eight preset buttons, their tooltips and their `time-button` class: from
  `PRESETS`.
- Three `Gtk::WindowControls`, three `Gtk::SpinButton`, two
  `Gtk::Label.custom-label`: from private factories.
- The five model signals (`a_active`, `b_active`, `pause`, `awbb`, `abbw`) and
  the three timer signals: emitted through `Signals#emit` with symbol names,
  which no GTK-signal regex matches on either side.
- `css-name button`: upstream calls `set_css_name("button")` on its
  `Gtk.Button` subclass; the port does not, and does not need to, because
  `Gtk::Button`'s css name is already `button`.
