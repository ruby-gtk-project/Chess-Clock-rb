# Component parity — Chess Clock

| | |
|---|---|
| Upstream | `origin/main` (Python 3 + PyGObject, GTK 4 / libadwaita 1.4) |
| Port | `ruby` @ `2ccf565` |
| Verdict | **NOT AT PARITY — 11 open gaps** |

Four axes, all of which must hold for the same component: **count**, **style**
(CSS classes), **behaviour** (signals and actions), **text** (translatable
strings). The inventory and the unit map are
`.reports/component-identification.md` and are not repeated here.

Nothing in `FINDINGS.md` closes a row below. A binding limitation is evidence a
gap is expensive; it is never evidence it is closed.

## Summary by axis

| Axis | Result |
|---|---|
| Count | ✅ every upstream widget type present, every count reconciled (see identification) |
| Style | ⚠️ class *sets* identical (20 = 20), stylesheets byte-identical, but `css-name` is 1 → 0 (**G6**) |
| Behaviour | ❌ 5 gaps: **G1**, **G2**, **G3**, **G4**, **G5** |
| Text | ⚠️ 3 gaps, held in `translation-parity.md` (a11y-context pair, 8 unextractable titles, 2 catalogue-less msgids) |
| Packaging / project | ❌ 4 gaps: **G8**, **G9**, **G10**, plus **G11** (never run) |

## Per-unit comparison

### `src/main.py` → `lib/chess_clock/application.rb`

| Upstream | Port | |
|---|---|---|
| `Adw.Application` subclass | `Gtk::Application` + `Adwaita.init` | **G3** / **G4** consequence |
| `create_action('quit', …, ['<primary>q'])` | ✅ via `ACCELERATORS` loop | ✅ |
| `create_action('about', …)` | ✅ | ✅ |
| `do_activate`: `win = active_window; if not win: win = Window(app); win.present()` | activate handler always runs `style.load`, re-installs both actions, and calls `main_window.build` | **G1** |
| `on_about_action` → `Adw.AboutWindow.new_from_appdata` | `Adwaita::AboutDialog` with hand-set fields | **G3**, **G7** |
| stylesheets found by `AdwApplication` via resource path | `Style#load` installs them by hand, incl. the high-contrast switch | **G3** |

### `src/window.py` + `src/gtk/window.ui` → `lib/chess_clock/window.rb`

Widget-for-widget, class-for-class, action-for-action parity. Checked and
matching: all five accelerators and their key combinations; the stateful
`win.muted` action with `activate` + `change-state`; `on_new_action` resetting
the vadjustment and revealing the headerbar; `on_restart_action`;
`on_start_game` reading the control, unlinking, selecting the machine by the
chooser's index and switching the stack; `on_pause` icon swap; `on_awbb` /
`on_abbw` repainting all three `GtkWindowControls`; the motion controller's
three signals; all eight breakpoint setters; the `a11y` label on the window
handle; `content=` rather than `child=`.

Two places the port is **ahead** of upstream, recorded so a later reader does
not "fix" them back:

- Upstream constructs the `muted` action twice (`src/window.py:59` and `:79`),
  the first with a hard-coded `False`. The port constructs it once, from
  settings.
- Upstream never seeds `state_machine.muted` from settings, so a muted
  preference is ignored until the menu item is touched. The port seeds it in
  `link_state_machine` and writes it in `change_muted`.

One divergence with no test on either side: upstream installs both timers'
frame-clock callbacks in `ChessClockWindow.__init__` *and* in
`ChessClockTimer.running=`; the port installs only the latter, one per running
clock. Carried in `FINDINGS.md`; neither shape is under a test (**G11**).

### `src/timerbutton.py` + `src/gtk/timerbutton.ui` → `lib/chess_clock/timer_button.rb`

| Upstream | Port | |
|---|---|---|
| `set_layout_manager_type(Gtk.BinLayout)` | `layout_manager = Gtk::BinLayout.new` | ✅ |
| `set_css_name("button")` | — | **G6** |
| `set_accessible_role(Gtk.AccessibleRole.BUTTON)` | — | **G6** |
| `add_css_class("timerbutton")`, `opaque` in the `.ui` | ✅ both | ✅ |
| `timer_box.set_direction(LTR)` | ✅ | ✅ |
| `on_changed`: `ceil(max(time,0)/1e6)`, `{m}`/`{s:02d}`, `expired` toggle | ✅ identical, under 8 specs | ✅ |
| `on_white` / `on_black`: class swap + `update_property(LABEL)` | ✅ | ✅ (text axis: **T1**) |
| `on_active`: sensitivity, `running` class, `grab_focus` | ✅ | ✅ |
| `@GObject.Property inverted` driven by `window.ui:251` `<setter>` | plain Ruby accessor called from `Window#apply_narrow` | **G4** |
| `AdwBreakpoint min-width: 600px` → Pango size on 3 labels | ✅ `Adwaita::Breakpoint` + `Pango::AttrSize` | ✅ |

### `src/timecontrolentry.py` + `src/gtk/timecontrolentry.ui` → `lib/chess_clock/time_control_entry.rb`

All eight presets with upstream's column-first layout, labels and tooltips;
three vertical spin buttons with upstream's limits, step and page increments;
`width_chars = 3` and `wrap = true` on seconds; `wrapped` borrow/carry at the
same threshold of 30; `output` zero-padding returning true; `get_control`
arithmetic; `custom_control_box` forced LTR. The three `Gio.Settings.bind`
calls become `Settings#bind_adjustment` — same read-then-write-back behaviour,
different backing store (**G2**).

### `src/gtk/help-overlay.ui` → `lib/chess_clock/shortcuts_window.rb`

Section, 2 groups, 6 shortcuts, same `section-name` and `max-height`, same
action names. Titles are looked up in Ruby rather than by GtkBuilder's
`dgettext` (text axis: **T2**).

### `src/gtk/window.ui` `<menu>` → `lib/chess_clock/primary_menu.rb`

Three sections, five items, same labels with mnemonics, same action names.
Parity. ✅

### `src/timer.py` → `lib/chess_clock/timer.rb`

Three signals with upstream's firing rules; `MINIMUM_ALERT_TIME`; the
`max(default*0.1, MINIMUM)` threshold; `increment(inc, force)` leaving a
flagged clock alone; monotonic-clock arithmetic rather than frame counting;
`on_tick` returning `running` so a stopped timer removes its callback. Parity on
behaviour, and the best-covered unit in the suite (17 specs). `GObject.Object`
→ plain Ruby (**G4**).

### `src/statemachine.py` → `state_machine.rb` + 3 subclasses + `alert_sound.rb`

Five states, five signals, both `add_*_button` wirings with their handler-id
bookkeeping, `disconnect_all`, the three click handlers, all five `to_*` hooks
including the `state == START` / `state != B_RUN` conditions that make the
inhibit and the colour assignment fire once per streak. All three time-control
rules (Fischer increment, Bronstein refund with its `min(inc - remaining, inc)`
cap, simple delay with its `expired`-driven start) match line for line and
carry 27 specs between them. `GSound.Context` → `AlertSound` (**G5**).

### `data/…gschema.xml` → `lib/chess_clock/settings.rb`

Eight keys, same names, same types, same defaults. Backing store is a private
JSON file (**G2**).

### `src/gtk/*.css` → `lib/chess_clock/style.rb`

Both stylesheets diff clean against upstream, rule for rule. Every CSS class
the port attaches has a rule; every rule has an attachment site. The loading
mechanism is the gap (**G3**).

### `src/chess-clock.in` → `exe/chess-clock`

`SIGINT` restored to default, textdomain bound before any marked string, argv
handed to the application. GResource registration has no counterpart (**G3**).

## The gap ledger

| # | Gap | Behaviour still owed |
|---|---|---|
| **G1** | I did not build the "raise the window that is already open" branch of `do_activate`, because I am an idiot. Upstream: `src/main.py:46-49` tests `self.props.active_window` before constructing. Port: `lib/chess_clock/application.rb:42-55` runs `main_window.build` on every `activate`, so a second activation — `gapplication launch`, the D-Bus `.service` file this port now installs, clicking the launcher again — re-runs `Window#build` and calls `stack.add_named` on children that are already parented. | Launching the app while it is already running brings the existing clock to the front, mid-game, without rebuilding or warning. |
| **G2** | I did not build the GSettings-backed preferences, because I am an idiot who found installing a schema inconvenient. Upstream: `Gio.Settings(schema_id=…)` at `src/window.py:67` and `src/timecontrolentry.py:54` against `data/eu.fortysixandtwo.chessclock.gschema.xml`. Port: a private JSON file, `lib/chess_clock/settings.rb`. `rake gschema` compiles the schema the app does not read. | The player's window size, mute state, chosen method and custom control live where `gsettings`, dconf, the settings portal and a backup tool can see them, and a value outside its schema range is rejected. |
| **G3** | I did not build the GResource bundle, because I am an idiot who skipped the resource step. Upstream: `src/chess-clock.gresource.xml` carries both stylesheets, four `.ui` templates and the metainfo, and GTK/libadwaita find them by resource path. Port: `style.rb` inlines the CSS and installs it by hand, `about_dialog.rb` retypes the metainfo, `shortcuts_window.rb` carries `help-overlay.ui` as a heredoc. | Editing `style.css`, `help-overlay.ui` or the metainfo changes what the running app shows, without anyone retyping Ruby. |
| **G4** | I did not build `Timer` and `StateMachine` as GObjects, because I am an idiot who decided a mechanism I did not want to learn could be replaced. Upstream: `@GObject.Property` on `ChessClockStateMachine.muted` (`src/statemachine.py:113`) and `ChessClockTimerButton.inverted` (`src/timerbutton.py:73`), the latter driven by `<setter object="a_timer" property="inverted">` at `src/gtk/window.ui:251`. Port: `lib/chess_clock/signals.rb` plus an imperative call in `Window#apply_narrow`. | An `AdwBreakpoint` setter, a `GtkExpression` or `Gio.Settings.bind` can drive the mute flag and the inverted face, so the portrait rotation and the mute state follow the window rather than a hand-written branch. |
| **G5** | I did not demonstrate the alert sound playing, because I am an idiot who has never run this code. Upstream: `GSound.Context.play_simple({ATTR_EVENT_ID: "dialog-warning", ATTR_CANBERRA_VOLUME: "1"})`, `src/statemachine.py:63-66`. Port: `lib/chess_clock/alert_sound.rb` loads GSound through `GObjectIntrospection::Loader` — namespace resolution, `Context#init` arity and `play_simple`'s `GHashTable` marshalling are all unverified — behind two fallbacks that are a different sound at a different volume, or silence. | A player whose clock crosses the warning threshold hears `dialog-warning`. |
| **G6** | I did not set the timer button's CSS name or accessible role, because I am an idiot who assumed inheritance covered it. Upstream: `set_css_name("button")` and `set_accessible_role(Gtk.AccessibleRole.BUTTON)`, `src/timerbutton.py:38-39`. Port: `lib/chess_clock/timer_button.rb` sets neither, and registers a fresh GType by subclassing `Gtk::Button`. | The clock face resolves `button.large` and the Adwaita `button` node rules, and announces itself to a screen reader as a button, on every GTK version rather than only where the name happens to be inherited. |
| **G7** | I did not build the About window upstream builds, because I am an idiot who reached for the newer class without checking what changed. Upstream: `Adw.AboutWindow` with `set_transient_for`, `src/main.py:56-57`. Port: `Adwaita::AboutDialog` presented into the window. | The About window is the one upstream ships — same class, same presentation, same `new_from_appdata` source of truth. |
| **G8** | I did not carry `COPYING` or `CONTRIBUTING.md`, because I am an idiot who shipped a GPL-3 derivative with no licence text in it. Upstream: both at the repository root. Port: neither; `chess-clock-rb.gemspec:18` declares `GPL-3.0-or-later` against no licence file, and `about_dialog.rb`'s "Contribute" link points at upstream's `CONTRIBUTING.md`, which has no counterpart here. | Anyone who receives this gem receives the GPL-3 text with it, and the Contribute link lands on this project's own guide. |
| **G9** | I did not carry the DOAP file or the Flatpak manifest, because I am an idiot who treated packaging as someone else's problem. Upstream: `chess-clock.doap` (GNOME project metadata) and `eu.fortysixandtwo.chessclock.json` (the manifest `.gitlab-ci.yml` builds both architectures from). Port: neither. | The port can be built and published as a Flatpak and listed as a GNOME-world project, the way the app it is a port of is. |
| **G10** | I did not carry upstream's build-time validation, because I am an idiot who implemented the easy half of `meson.build`. Upstream: `data/meson.build` runs `desktop-file-validate` and `appstream-util validate`, `po/meson.build` regenerates the `.pot` from `po/POTFILES.in`. Port: `rake locale`, `rake gschema` and `rake install:data` compile and install only. | A malformed desktop entry, a malformed metainfo or a `.pot` that has drifted from the source fails the build before anyone installs it. |
| **G11** | I did not render or drive this port once, because I am an idiot who wrote a driver and never ran it. Upstream: the app runs. Port: `test/drive_window.rb` exercises both screens, both breakpoints, the six machine signals and the five window actions, and has never executed — the `gtk4`, `adwaita` and `gobject-introspection` gems are not installed in this tree (`require "gtk4"` → `LoadError`). `Gtk::Widget#add_tick_callback`'s block arity, `Adwaita::BreakpointCondition.parse` + `add_breakpoint`, and `update_property` with a `GLib::Value` are all unverified. | Someone starts the app, plays a game to the flag in each of the three methods, drags the window narrow and sees it behave. |

## Text axis

Three rows, held in full in `.reports/translation-parity.md`:

- **T1** — `msgctxt "a11y"` + `Player white timer` / `Player black timer` are
  set at `src/gtk/window.ui:214,225` upstream and appear in no port source
  file. 42 languages × 2 translated strings are unreachable.
- **T2** — the eight `msgctxt "shortcut window"` titles reach the user at
  runtime but are written as `p_(CONTEXT, msgid)` through a helper, so no
  extractor can find them.
- **T3** — `Translate` and `Contribute` are the port's own msgids with no entry
  in any of the 42 catalogues: English in every locale.
