# Component identification — Chess Clock

| | |
|---|---|
| Upstream | `origin/main` (Python 3 + PyGObject, GTK 4 / libadwaita 1.4) |
| Port | `ruby` @ `2ccf565` |
| Scope | whole app |
| Tooling | `component-identification/scripts/component-scan.sh` over both trees |

Upstream splits almost every component across a `.py` subclass and its `.ui`
template, so the component is the *pair*. The unit map below is what
`component-parity.md` joins on; the rows of every upstream file on the left of
an arrow are unioned before anything is compared.

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
| `src/statemachine.py` (`MachineState` + base class) | `lib/chess_clock/state_machine.rb` |
| `src/statemachine.py` (3 subclasses) | `increment_state_machine.rb`, `bronstein_state_machine.rb`, `delay_state_machine.rb` |
| `src/statemachine.py` (`GSound.Context`) | `lib/chess_clock/alert_sound.rb` |
| `src/gtk/style.css` + `src/gtk/style-hc.css` | `lib/chess_clock/style.rb` (heredocs) |
| `data/…gschema.xml` | `lib/chess_clock/settings.rb` (JSON shim) |
| GObject signal plumbing in `timer.py` / `statemachine.py` | `lib/chess_clock/signals.rb` |
| `src/chess-clock.in` | `exe/chess-clock` |
| `data/…desktop.in`, `…metainfo.xml.in`, `…service.in`, `…gschema.xml`, `data/icons/**`, `data/screenshots/**` | the same paths, **byte-identical** |
| `po/*.po` (42), `po/LINGUAS` | the same paths, **byte-identical** |
| `po/POTFILES.in` | retargeted at `lib/` |
| **`src/chess-clock.gresource.xml`** | **nothing** |
| **`meson.build`, `src/meson.build`, `data/meson.build`, `data/icons/meson.build`, `po/meson.build`** | `Rakefile` tasks `locale`, `gschema`, `install:data` — partial (see parity G10) |
| **`COPYING`** | **nothing** |
| **`CONTRIBUTING.md`** | **nothing** |
| **`chess-clock.doap`** | **nothing** |
| **`eu.fortysixandtwo.chessclock.json`** (Flatpak manifest) | **nothing** |
| **`.gitlab-ci.yml`** | **nothing** |

Five upstream files on the left of an arrow have nothing opposite them. Those
are found here, not in any diff, and they are carried into
`component-parity.md` as G8–G10.

## Whole-app scan totals

Only the `widget` stream's counts are per-instance; `css`, `signal` and
`action` counts are attachment sites in the text, so a port that factors
upstream's repeats into a helper legitimately reads lower.

| Stream | Upstream rows | Port rows | Distinct upstream | Distinct port |
|---|---:|---:|---:|---:|
| `widget` | 60 | 47 | 24 | 25 |
| `controller` | 1 | 1 | 1 | 1 |
| `type` | 15 | 26 | 9 | 16 |
| `css` | 55 | 28 | 20 | 20 |
| `css-name` | 1 | **0** | 1 | **0** |
| `signal` | 37 | 23 | 16 | 14 |
| `action` | 12 | 7 | 12 | 7 |

The distinct CSS-class sets are equal, which is the shape of a UI laid out from
the inventory rather than guessed. Two totals are real findings and not scan
artefacts:

- **`css-name` 1 → 0.** `src/timerbutton.py:38` calls `set_css_name("button")`
  and `:39` `set_accessible_role(Gtk.AccessibleRole.BUTTON)`. The port's
  `TimerButton` does neither (parity G6).
- **`signal` "only upstream"** is `a-active`, `b-active`, `pause`, `awbb`,
  `abbw`, `changed`, `expired`, `alerted` — upstream's eight `@GObject.Signal`
  declarations. All eight exist in the port as `ChessClock::Signals` symbols,
  which the scan cannot see. Not a gap, but see parity G4: they are not GObject
  signals, so nothing can bind them.

`signal` "only port" is `apply`, `unapply`, `notify::selected`,
`notify::high-contrast`, `value-changed` — the breakpoint, settings-binding and
style-manager connections the port makes by hand because it has no `.ui`
`<setter>`s, no `Gio.Settings.bind` and no `AdwApplication`. Each is explained
below in the file it belongs to.

## Widget counts, reconciled

| Type | up | port | Reconciliation |
|---|---:|---:|---|
| `Gtk.Button` | 12 | 4 | port builds the 8 presets in a loop over `PRESETS` — 4 literal sites + 8 instances. ✅ |
| `Gtk.SpinButton` | 3 | 1 | `#spin_button` helper, 3 call sites. ✅ |
| `Gtk.WindowControls` | 3 | 1 | `#window_controls` helper, 3 call sites. ✅ |
| `Gtk.Label` | 7 | 6 | `#custom_label` helper, 2 call sites. ✅ |
| `Gtk.Box` | 8 | 7 | upstream's 8th row is `parent="GtkBox"` on the `timecontrolentry` template root — the same box counted twice. ✅ |
| `Adw.ApplicationWindow` | 2 | 1 | upstream's 2nd row is the `.ui` `<template parent=…>` for the same window. ✅ |
| `Adw.AboutWindow` | 1 | 2 | port rows are prose references; the port builds `Adw.AboutDialog` instead (parity G7). ⚠️ |

Every other widget type matches 1:1. No upstream widget type is absent from the
port.

## Port inventory, in the order a user meets the app

### `lib/chess_clock/application.rb` — the application singleton

| Widget / item | × | CSS | Signals / actions | Notes |
|---|---:|---|---|---|
| `Gtk::Application` | 1 | — | `activate` | id `eu.fortysixandtwo.chessclock`, `:default_flags`. `Adwaita::Application` not used, so `Adwaita.init` is called by hand |
| action `app.quit` | 1 | — | `<primary>q` | built in a loop over `ACCELERATORS`, so the name is a variable the scan cannot see |
| action `app.about` | 1 | — | no accel | opens `AboutDialog` |
| `Style#load` | — | — | `notify::high-contrast` | installs both stylesheets on the default display; upstream gets this free from `AdwApplication` |

Repeaters: the two actions, from `ACCELERATORS`. Conditional: `@present`
suppresses `window.present` — a test seam with no upstream counterpart.
**The activate handler is unconditional** — it has no `if not win` guard
(parity G1).

### `lib/chess_clock/window.rb` — the application window

| Widget | × | CSS | Signals / actions | Notes |
|---|---:|---|---|---|
| `Adwaita::ApplicationWindow` | 1 | — | actions `win.new` `<primary>n`, `win.restart` `<primary>r`, `win.close` `<primary>w`, `win.menu` `F10`, `win.show-help-overlay` `<primary>question`, stateful `win.muted` | title, 360×294 size request, geometry from `Settings#apply_to`; takes `content=` |
| `Gtk::Stack` | 1 | — | — | `:slide_left_right`; pages `setup` / `timer` |
| `Adwaita::Breakpoint` | 1 | — | `apply`, `unapply` | `max-aspect-ratio: 1/1 or max-width: 520px`; upstream's eight `<setter>`s run imperatively in `apply_narrow` / `unapply_narrow` |
| `Gtk::WindowHandle` | 1 | — | — | a11y label `p_("a11y", "Select time controls")` |
| `Adwaita::ToolbarView` + `Adwaita::HeaderBar` | 1 + 1 | — | — | setup header |
| `Gtk::ScrolledWindow` | 1 | — | — | `hscrollbar_policy = :never`; `win.new` zeroes its vadjustment |
| `Gtk::Box` | 4 | `linked` (timer_box) | — | setup box (24, margins 42/36/12/12), welcome box (12), headerbar box, timer box (homogeneous) |
| `Gtk::Label` | 2 | `title-1` (1st) | — | "Welcome to Chess Clock", "Select time controls below to get started" |
| `Adwaita::PreferencesGroup` | 1 | — | — | — |
| `Adwaita::PreferencesRow` | 1 | — | — | `activatable = false`, hosts `TimeControlEntry` |
| `Adwaita::ComboRow` | 1 | — | `notify::selected` → `control-method` | model `Gtk::StringList` of the three method names |
| `Gtk::Button` (`start_game`) | 1 | `pill`, `suggested-action` | `clicked` → `on_start_game` | — |
| `Gtk::Overlay` | 1 | — | — | the timer screen |
| `Gtk::Revealer` | 1 | — | — | `crossfade`, `overflow visible`, revealed initially |
| `Gtk::EventControllerMotion` | 1 | — | `enter`, `motion`, `leave` | reveals/hides the floating headerbar |
| `Adwaita::HeaderBar` (timer) | 1 | `transparent` | — | there for the drag area, not to be seen |
| `Gtk::WindowControls` | 3 | `white` ×2, `black` ×1 | — | start, start-end (hidden), end; repainted by `awbb`/`abbw` |
| `Gtk::MenuButton` | 1 | `image-button`, `circular`, `osd` | menu model `PrimaryMenu` | tooltip "Main Menu" |
| `Gtk::Button` (`play_pause`) | 1 | `image-button`, `circular`, `osd`, `large` | `clicked` → machine `on_pause_clicked` | icon swapped by the `pause` signal |
| `TimerButton` | 2 | `white` / `black` | — | the two clock faces |

Repeaters: the five accelerator actions, and `paint_controls` applying
`white`/`black` to three controls from one helper. Conditional: `apply_narrow`
sets eight properties only while the breakpoint holds.

### `lib/chess_clock/timer_button.rb` — one player's clock face

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk::Button` (self) | 1 | `timerbutton`, `opaque`, `white`/`black`, `running`, `expired`, `inverted` | `on_changed`, `on_white`, `on_black`, `on_active` from the machine | `Gtk::BinLayout`, `hexpand`. **No `set_css_name`, no `set_accessible_role`** |
| `Adwaita::BreakpointBin` | 1 | — | — | 240×130 request |
| `Adwaita::Breakpoint` | 1 | — | `apply`, `unapply` | `min-width: 600px` → Pango size 100pt on all three labels |
| `Gtk::Box` | 1 | — | — | `halign center`, direction forced LTR |
| `Gtk::Label` | 3 | `colon` (2nd) | — | minutes, U+2236, seconds |

Dynamic CSS, every value it can take: `white`, `black`, `running`, `expired`,
`inverted`. a11y label alternates between the two no-context msgids.

### `lib/chess_clock/time_control_entry.rb` — the time-control picker

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk::Box` | 2 | — | — | container (vertical 6, margins 6), custom box (LTR) |
| `Gtk::Grid` | 1 | — | — | row/column spacing 6, column-homogeneous |
| `Gtk::Button` | 8 | `time-button` | `clicked` → `set_control` | the presets, column-first, each with upstream's tooltip |
| `Gtk::SpinButton` | 3 | `custom-spin` | `wrapped`, `output` (seconds only) | vertical; limits 999 / 59 / 999 |
| `Gtk::Label` | 2 | `custom-label` | — | U+2236 and `+` |
| `Gtk::Adjustment` | 3 | — | `value-changed` → settings | the stored custom control |

Repeaters: the 8 presets from `PRESETS`, the 3 spin buttons from
`#spin_button`, the 2 labels from `#custom_label`.

### `lib/chess_clock/primary_menu.rb` — the menu behind the circular button

Three sections, five items: `win.new`, `win.restart` | `win.muted` |
`win.show-help-overlay`, `app.about`. Mnemonics preserved. A `Gio::Menu` is not
a widget, so it produces no widget rows on either side; the count is item-for-item.

### `lib/chess_clock/shortcuts_window.rb` — the shortcuts window

`Gtk::ShortcutsWindow` 1, `Gtk::ShortcutsSection` 1, `Gtk::ShortcutsGroup` 2,
`Gtk::ShortcutsShortcut` 6 — identical to `help-overlay.ui`. Built from a
GtkBuilder string, because `GtkShortcutsWindow` takes its sections only through
`GtkBuildable`. Each shortcut names an action, not an accelerator, so the window
cannot drift from what is installed.

### `lib/chess_clock/about_dialog.rb` — the About window

`Adwaita::AboutDialog` 1, where upstream builds an `Adw.AboutWindow` from
`new_from_appdata`. Fields hand-set: name, icon, developer name, version 0.6.2,
comments, website, issue url, copyright, GPL-3.0, 4 developers, 1 artist,
translator credits, release notes, 2 extra links.

### Non-widget units

`timer.rb`, `state_machine.rb` and its three subclasses, `signals.rb`,
`settings.rb`, `alert_sound.rb`, `style.rb`, `translation.rb` build no widgets.
They are compared on the `type` and `signal` axes in `component-parity.md`.

## Identification-side gaps

The inventory itself is complete: every upstream widget type, every CSS class
and every menu item has a located counterpart. The two holes the inventory
*finds* are the five unmapped upstream files above and the missing `css-name`
row, and both are carried as parity gaps rather than closed here.
