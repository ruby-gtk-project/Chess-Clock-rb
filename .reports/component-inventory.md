# Chess Clock — upstream component inventory

Upstream: `origin/main`, Python 3 + PyGObject (GTK4 / libadwaita 1.4), GtkBuilder
`.ui` templates in `src/gtk/`, compiled into a GResource. A chess game clock:
pick a time control, then tap each player's half of the screen to hand over the
move.

Port target: branch `ruby`, namespace directory `lib/chess_clock/`. Today `lib/`
holds three files — `lib/chess_clock.rb` (one `require_relative`),
`lib/chess_clock/application.rb` (a blank Adwaita window with a "not written
yet" status page) and `lib/chess/clock/rb/version.rb`. That is skeleton only;
nothing below except the application shell exists.

Upstream splits most components across two files (the `.py` subclass and its
`.ui` template). The component is the pair.

## src/main.py — the application singleton

| Widget / item | × | CSS | Signals / actions | Notes |
|---|---:|---|---|---|
| `Adw.Application` | 1 | — | `activate` | app id `eu.fortysixandtwo.chessclock`, `FLAGS_NONE`; raises the existing window or builds one |
| `Adw.AboutWindow` | 1 | — | — | `new_from_appdata` on the metainfo in the GResource, version `0.6.0`; 4 developers, 1 artist, `translator-credits` |
| action `app.quit` | 1 | — | `<primary>q` | |
| action `app.about` | 1 | — | — | opens the About window |

Target: `lib/chess_clock/application.rb` (exists, skeleton) and
`lib/chess_clock/about_dialog.rb` (new — the port has no GResource, so the About
window must be populated field by field instead of from appdata).

## src/window.py + src/gtk/window.ui — the main window: setup screen and timer screen

Root `Adw.ApplicationWindow`, title "Chess Clock", 600×300 default,
360×294 minimum. Its content is a `Gtk.Stack` with two pages.

| Widget | × | CSS | Signals / actions | Notes |
|---|---:|---|---|---|
| `Adw.ApplicationWindow` | 1 | — | actions `win.new` `<primary>n`, `win.restart` `<primary>r`, `win.close` `<primary>w`, `win.menu` `F10`, stateful `win.muted`; `win.show-help-overlay` comes free from GtkApplication upstream | binds `width`, `height`, `is-maximized` to GSettings |
| `Gtk.Stack` `main_stack` | 1 | — | — | `slide-left-right`; pages `control_chooser` and `timer_screen` |
| `Adw.Breakpoint` | 1 | — | — | `max-aspect-ratio: 1/1 or max-width: 520px` → timer box vertical, menu to the end/centre, play-pause to the start/centre, second window-controls visible, `a_timer.inverted = true` |

### Setup screen (stack page 1)

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk.WindowHandle` `control_chooser` | 1 | — | — | a11y label "Select time controls" |
| `Adw.ToolbarView` + `Adw.HeaderBar` | 1 + 1 | — | — | plain header |
| `Gtk.ScrolledWindow` `control_chooser_scroll` | 1 | — | — | `hscrollbar-policy: never`; `win.new` resets its vadjustment to 0 |
| `Gtk.Box` | 3 | — | — | vertical page box (spacing 24, margins 42/36/12/12), title box (spacing 12) |
| `Gtk.Label` | 2 | `title-1` (1st) | — | "Welcome to Chess Clock", "Select time controls below to get started" |
| `Adw.PreferencesGroup` | 1 | — | — | |
| `Adw.PreferencesRow` | 1 | — | — | `activatable: false`, hosts the time-control entry |
| `ChessClockTimeControlEntry` `custom_control` | 1 | — | — | composite, see below |
| `Adw.ComboRow` `method_chooser` | 1 | — | bound to GSettings `control-method` | `Gtk.StringList`: Increment, Bronstein delay, Simple delay |
| `Gtk.Button` `start_game` | 1 | `pill`, `suggested-action` | `clicked` → `on_start_game` | reads the entry, builds the chosen state machine, switches the stack, hides the header revealer |

### Timer screen (stack page 2)

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk.Overlay` `timer_screen` | 1 | — | — | timer box as child, six overlays |
| `Gtk.Revealer` `headerbar_revealer` | 1 | — | — | crossfade; revealed on pointer enter/motion, hidden on leave and when a game starts |
| `Adw.HeaderBar` | 1 | `transparent` | — | `opacity: 0` — invisible, exists only for its drag area and controls |
| `Gtk.EventControllerMotion` `headerbar_motion` | 1 (controller) | — | `enter`, `motion` → `reveal_headerbar`; `leave` → `hide_headerbar` | |
| `Gtk.WindowControls` | 3 | `white` / `black`, swapped per side on `awbb`/`abbw` | — | `windowcontrols_start` (start side), `windowcontrols_start_end` (end side, hidden until the breakpoint), `windowcontrols_end` (end side, hidden by the breakpoint) |
| `Gtk.MenuButton` `main_menu` | 1 | `image-button`, `circular`, `osd` | menu model `primary_menu`; `win.menu` activates it when the timer screen is up | `open-menu-symbolic`, tooltip "Main Menu" |
| `Gtk.Button` `play_pause` | 1 | `image-button`, `circular`, `large`, `osd` | `clicked` → state machine `on_pause_clicked` | icon swaps `media-playback-pause-symbolic` / `media-playback-start-symbolic`; insensitive while stopped |
| `Gtk.Box` `timer_box` | 1 | `linked` | — | homogeneous, horizontal; vertical at the breakpoint |
| `ChessClockTimerButton` | 2 | `white` (a), `black` (b) | see below | a11y labels "Player white timer" / "Player black timer" |

Behaviour worth keeping: `link_state_machine` / `unlink_state_machine` wire and
tear down every signal between the window, the two timer buttons and the state
machine, including two `add_tick_callback` registrations; `win.muted` is a
stateful action persisted to GSettings `muted`.

Target: `lib/chess_clock/window.rb`.

## src/gtk/window.ui — `menu primary_menu`

Three sections, five items, no backing source file.

| Item | Action |
|---|---|
| _New Time Control | `win.new` |
| _Restart Timer | `win.restart` |
| _Mute Alert Sound | `win.muted` (stateful, shows a check) |
| _Keyboard Shortcuts | `win.show-help-overlay` |
| _About Chess Clock | `app.about` |

Target: `lib/chess_clock/primary_menu.rb`.

## src/gtk/help-overlay.ui — keyboard shortcuts window

`Gtk.ShortcutsWindow` `help_overlay`, modal, one section (`max-height: 10`),
two groups, six shortcuts. Auto-wired to `win.show-help-overlay` upstream by
GtkApplication's resource convention.

| Group | Shortcuts |
|---|---|
| Game | New Time Control (`win.new`), Restart Timer (`win.restart`) |
| General | Open Main Menu (`win.menu`), Show Shortcuts (`win.show-help-overlay`), Close Window (`win.close`), Quit (`app.quit`) |

Target: `lib/chess_clock/shortcuts_window.rb`.

## src/timerbutton.py + src/gtk/timerbutton.ui — one player's clock face

`Gtk.Button` subclass, `BinLayout`, css name `button`, accessible role BUTTON.

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `ChessClockTimerButton` (`Gtk.Button`) | 1 | `opaque`, `timerbutton`, plus `white`/`black`, `running`, `expired`, `inverted` all set dynamically | `clicked` → state machine `on_a_clicked`/`on_b_clicked`; handlers `on_changed`, `on_white`, `on_black`, `on_active` | `inverted` is a GObject property; `on_active` grabs focus when this side is live; a11y label updated by `on_white`/`on_black` |
| `Adw.BreakpointBin` | 1 | — | — | 240×130 request |
| `Adw.Breakpoint` | 1 | — | — | `min-width: 600px` → Pango `size 102400` on all three labels |
| `Gtk.Box` `timer_box` | 1 | — | — | forced LTR so the digits never mirror |
| `Gtk.Label` | 3 | `colon` (middle) | — | `minutes`, `∶`, `seconds` (`%02d`); time ceil'd from microseconds |

Target: `lib/chess_clock/timer_button.rb`.

## src/timecontrolentry.py + src/gtk/timecontrolentry.ui — time control picker

`Gtk.Box` subclass, vertical, spacing 6, margins 6.

| Widget | × | CSS | Signals | Notes |
|---|---:|---|---|---|
| `Gtk.Grid` | 1 | — | — | 4 columns × 2 rows, homogeneous columns, spacing 6 |
| `Gtk.Button` | 8 | `time-button` | `clicked` → `set_control(min, sec, inc)` | 1+0, 2+1, 5+0, 5+3, 10+0, 10+5, 30+0, 30+20, each with a translated tooltip |
| `Gtk.Box` `custom_control_box` | 1 | — | — | forced LTR |
| `Gtk.SpinButton` | 3 | `custom-spin` | `seconds`: `wrapped` → carry into minutes, `output` → `%02d` | `minutes` (0–999), `seconds` (0–59, wrapping, 3 chars wide), `increment` (0–999); each bound to GSettings and backed by a `Gtk.Adjustment` |
| `Gtk.Label` | 2 | `custom-label` | — | `∶` and `+` |

`get_control` returns `(minutes*60 + seconds, increment)` in seconds.

Target: `lib/chess_clock/time_control_entry.rb`.

## src/timer.py — one countdown (model)

`GObject.Object`, not a widget. Microsecond resolution off
`GLib.get_monotonic_time`, driven by the window's frame tick callback. Signals
`changed(uint64)`, `expired`, `alerted`. Alerts at
`max(10% of default time, 10 s)`. `increment(inc, force:)` adds time, skipping
an already-expired clock unless forced.

Target: `lib/chess_clock/timer.rb`.

## src/statemachine.py — the game rules (model)

`MachineState` enum (START, A_RUN, B_RUN, A_PAUSE, B_PAUSE) and four classes.
Signals `a_active(bool, bool)`, `b_active(bool, bool)`, `pause(bool, bool)`,
`awbb`, `abbw`. Holds a `GSound.Context` and plays `dialog-warning` on
`alerted` unless muted; inhibits session idle (`ApplicationInhibitFlags.IDLE`,
"Game clock running") while a clock runs; `add_a_button`/`add_b_button` wire a
timer button in and `disconnect_all` unwires it.

| Class | Rule | Target |
|---|---|---|
| `ChessClockStateMachine` | base transitions, sound, idle inhibit, button wiring | `lib/chess_clock/state_machine.rb` |
| `ChessClockIncrementStateMachine` | Fischer increment: add `inc` on handover and at start | `lib/chess_clock/increment_state_machine.rb` |
| `ChessClockBronsteinStateMachine` | Bronstein delay via a third `inc_timer`: give back only the time used, capped at `inc` | `lib/chess_clock/bronstein_state_machine.rb` |
| `ChessClockDelayStateMachine` | Simple (US) delay: a `delay_timer` holds the main clock until it expires | `lib/chess_clock/delay_state_machine.rb` |

## data/eu.fortysixandtwo.chessclock.gschema.xml — settings

Eight keys: `width` (640), `height` (480), `is-maximized` (false),
`custom-control-minutes` (5), `custom-control-seconds` (0),
`custom-control-increment` (0), `control-method` (0), `muted` (false).

Target: `lib/chess_clock/settings.rb`.

## src/gtk/style.css + src/gtk/style-hc.css — stylesheet

Loaded automatically upstream by `AdwApplication` from the GResource base path
(`style.css`, and `style-hc.css` under high contrast). Defines
`button.large`, `.timerbutton` (70 px, tabular numerals, weight 100, 240 px
min-width, square corners), `.black`/`.white` plus their `:backdrop` variants,
`.inverted box` (180° rotation), `.timerbutton.{black,white}` brown
backgrounds, `.timerbutton.running`, `.expired` and
`.timerbutton.expired.{black,white}` red backgrounds, `:focus-visible`
outlines per side, `label.colon`, `label.custom-label`, `button.time-button`,
`spinbutton.custom-spin`, `headerbar.transparent`.

Every one of these classes is applied somewhere above; none is dead. The port
has no GResource, so they must be loaded through a `Gtk::CssProvider` with a
high-contrast variant switched off `Adwaita::StyleManager`.

Target: `lib/chess_clock/style.rb`.

## Alert sound

`GSound.Context` in `statemachine.py` — `play_simple` with event id
`dialog-warning` at volume 1, suppressed when `muted`. Worth its own file in
the port because GSound has no Ruby binding.

Target: `lib/chess_clock/alert_sound.rb`.

## Translations

`po/` carries 42 locales and `po/POTFILES.in` lists both the `.py` sources and
all four `.ui` files. Translatable strings: the window title, the two welcome
labels, "Time control method" and its three methods, "Start Game", the eight
time-control tooltips, the three spin-button tooltips, "Main Menu", "Toggle
Pause", the five menu items, the six shortcut titles and their two group
titles, the two a11y timer labels, "Select time controls", and
`translator-credits`.

## Engineering notes

The binding limitations, substitutions and divergences this port runs into
are in `FINDINGS.md`. They are not reasons: every behaviour they touch is
still owed, and is still a gap in `.reports/component-parity.md`.
