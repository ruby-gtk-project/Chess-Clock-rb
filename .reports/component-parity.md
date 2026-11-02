# Component parity — Chess Clock

| | |
|---|---|
| Upstream | `origin/main` @ `775f046` |
| Port | `ruby` @ `270aa8a` |
| Units with parity | **0 / 12** |
| Stylesheet | both sheets byte-identical to upstream |
| Text axis | 0 / 50 messages marked |
| Checks that did not run | the app was never launched (the `gtk4` gem is not installed in this shell), so **Step 4's render check and Step 5's drive check were not performed for any unit**. No screenshot was taken and no signal was driven. Nothing below is a claim that the port runs. |

The unit map is in `.reports/component-identification.md`. Counts below are the
union of every upstream file on the left of an arrow against the union of the
port files on the right, with the template-root double count struck.

## The six upstream files with nothing opposite them

Found at the mapping step, which is where the largest gaps live.

| Upstream | What a user loses | Verdict |
|---|---|---|
| `data/eu.fortysixandtwo.chessclock.desktop.in` | No desktop entry: the app does not appear in the shell's app grid or search, has no `Keywords=chess;game;clock;timer;`, no `Categories`, no `X-Purism-FormFactor=Workstation;Mobile;`, and no `DBusActivatable=true` | **gap** |
| `data/eu.fortysixandtwo.chessclock.service.in` | No D-Bus service file, so D-Bus activation cannot work even if the desktop entry asked for it | **gap** |
| `data/eu.fortysixandtwo.chessclock.metainfo.xml.in` | No AppStream data: the app cannot be listed or installed from a software centre, has no summary, description, screenshots, categories, keywords or release history, and the About window therefore has no release notes | **gap** |
| `data/icons/hicolor/scalable/apps/eu.fortysixandtwo.chessclock.svg`, `…-symbolic.svg`, `…Devel.svg`, `…Source.svg` | No application icon anywhere: window, task switcher, app grid and the About window all fall back to a placeholder. `about_dialog.rb:21` sets `application_icon = "eu.fortysixandtwo.chessclock"`, which resolves to nothing | **gap** |
| `data/eu.fortysixandtwo.chessclock.gschema.xml` | Settings are a private JSON file instead of GSettings, so `gsettings`/dconf cannot read or set them, no schema range validation applies, and nothing else on the system can observe a change | **gap** |
| `po/` (42 `.po`, `LINGUAS`, `POTFILES.in`) | See `translation-parity.md`. 42 languages and 2,004 translated strings are not shipped | **gap** |

Also absent as a *target*: the gem packages `lib` and `exe` only
(`chess-clock-rb.gemspec:72-79`) and declares no runtime dependency on `gtk4`,
`adwaita` or `gio2`, so there is no mechanism by which `data/` or `po/` could
ship even once written, and an installed gem's `chess-clock` raises `LoadError`
on its first `require`. **gap**.

## Unit: application — `src/main.py` → `lib/chess_clock/application.rb`

| Item | Up × | Port × | CSS | Signals / actions | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| application object | 1 | 1 | — | ✓ `activate` | — | correspondence: `Adw.Application` → `Gtk::Application` + `Adwaita.init`, because `Adwaita::Application` is unusable from Ruby. The two conveniences it carries are both reproduced by hand (`Style#load`, and `win.show-help-overlay` installed explicitly) |
| application id | 1 | 1 | — | — | — | **gap**: `eu.fortysixandtwo.chessclock` → `org.rubygtkproject.ChessClock`. The id is the GSettings path, the D-Bus well-known name, the `.desktop` basename and the icon name all at once; changing it detaches the port from every one of upstream's installed files, and from the app id in `about_dialog.rb` |
| action `app.quit` | 1 | 1 | — | ✓ `<primary>q` | — | parity |
| action `app.about` | 1 | 1 | — | ✓ no accel | — | parity |
| argv handling | 1 | 1 | — | — | — | **gap**: upstream runs `app.run(sys.argv)` (`main.py:85`); `application.rb:54` runs `app.run([])`, so every command-line argument is silently discarded instead of reaching GApplication |

Messages: 1 upstream (`translator-credits`), present as a bare literal in
`about_dialog.rb:42`, unmarked. **gap**.
Driven: not run.

## Unit: about window — `src/main.py` + metainfo → `lib/chess_clock/about_dialog.rb`

| Item | Up × | Port × | CSS | Signals | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| `Adw.AboutWindow` → `Adwaita::AboutDialog` | 1 | 1 | — | — | ✗ | substitution: `AboutDialog` is the newer equivalent of `AboutWindow`, which upstream is behind on. Recorded, not silent |
| name, icon, developer name, website, issue url, licence, 4 developers, 1 artist, translator credits | — | — | — | — | — | present; upstream reads them from the appdata in its GResource, the port sets them field by field |
| release notes | 1 | 0 | — | — | — | **gap**: `new_from_appdata` populates `release-notes` and `release-notes-version` from `<releases>`. The port sets neither, so the About window's "What's New" is gone |
| `translate` url (`https://l10n.gnome.org/module/chess-clock/`) | 1 | 0 | — | — | — | **gap** |
| `contribute` url (`CONTRIBUTING.md`) | 1 | 0 | — | — | — | **gap** |
| `comments` | 1 | 1 | — | — | ✗ | **gap**: upstream's msgid is `Time games of over-the-board chess`; `about_dialog.rb:24` writes `Time games of over-the-board chess.` — one added character, which is a different gettext key. Also recorded in `translation-parity.md` |
| version string | 1 | 1 | — | — | — | note: upstream passes the literal `"0.6.0"` while its `meson.build` says `0.6.2`; the port writes `0.6.2`. The port is right and upstream is stale, but the divergence is recorded rather than assumed |
| developers list | 1 | 1 | — | — | — | note: upstream's first entry is `Clara Hobbs‍️` (U+200D, U+FE0F); `about_dialog.rb:30` strips both. Not a msgid, so not a translation gap, but it is not the name upstream credits |

## Unit: main window — `src/window.py` + `src/gtk/window.ui` → `lib/chess_clock/window.rb`

### Setup screen

| Widget | Up × | Port × | CSS | Signals | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| `Gtk.WindowHandle` | 1 | 1 | — | — | ✗ | a11y label present; `update_property` call **unverified** (not run) |
| `Adw.ToolbarView` + `Adw.HeaderBar` | 1+1 | 1+1 | — | — | — | parity |
| `Gtk.ScrolledWindow` | 1 | 1 | — | — | — | parity, `hscrollbar-policy: never` ✓ |
| `Gtk.Box` | 2 | 2 | — | — | — | parity (spacing and all four margins match) |
| `Gtk.Label` | 2 | 2 | ✓ `title-1` | — | ✗ | counts and class match; both strings unmarked |
| `Adw.PreferencesGroup` | 1 | 1 | — | — | — | parity |
| `Adw.PreferencesRow` | 1 | 1 | — | — | — | parity, `activatable: false` ✓ |
| `Adw.ComboRow` + `Gtk.StringList` (3) | 1 | 1 | — | ✓ bound to `control-method` | ✗ | parity on structure; 4 strings unmarked |
| `Gtk.Button` (start) | 1 | 1 | ✓ `pill`, `suggested-action` | ✓ `clicked` | ✗ | parity on structure; label unmarked |

### Timer screen

| Widget | Up × | Port × | CSS | Signals | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| `Gtk.Overlay` + 6 overlays | 1 | 1 | — | — | — | parity, same child/overlay split |
| `Gtk.Revealer` | 1 | 1 | — | — | — | parity, crossfade + `overflow: visible` ✓ |
| `Adw.HeaderBar` | 1 | 1 | ✓ `transparent` | — | — | parity |
| `Gtk.EventControllerMotion` | 1 | 1 | — | ✓ `enter`, `motion`, `leave` | — | parity (compared on the signal axis) |
| `Gtk.WindowControls` | 3 | 3 | ✓ `white`/`white`/`black`, repainted by `paint_controls` | — | — | parity. Scan reads 1 — the three come from the `window_controls(side)` factory |
| `Gtk.MenuButton` | 1 | 1 | ✓ `image-button`, `circular`, `osd` | ✓ menu model | ✗ | parity on structure; `Main Menu` unmarked |
| `Gtk.Button` (play/pause) | 1 | 1 | ✓ `image-button`, `circular`, `large`, `osd` | ✓ `clicked` | ✗ | parity on structure; `Toggle Pause` unmarked |
| `Gtk.Box` (timer box) | 1 | 1 | ✓ `linked` | — | — | parity, homogeneous ✓ |
| `ChessClockTimerButton` | 2 | 2 | ✓ `white`, `black` | ✓ | ✗ | see the timer-button unit |

### Actions, accelerators and the breakpoint

| Item | Up | Port | Verdict |
|---|---|---|---|
| `win.new` `<primary>n` | ✓ | ✓ | parity |
| `win.restart` `<primary>r` | ✓ | ✓ | parity |
| `win.close` `<primary>w` | ✓ | ✓ | parity |
| `win.menu` `F10` | ✓ | ✓ | parity |
| `win.muted` (stateful, persisted) | ✓ | ✓ | parity. Upstream registers the action twice (`window.py:59` and `window.py:79`, plainly a bug); the port registers it once |
| `win.show-help-overlay` | free from GtkApplication, accel `<Control>question` | installed explicitly, `<primary>question` | correspondence: the Ruby bindings have no resource convention to supply it |
| `Adw.Breakpoint`, 8 setters | ✓ | ✓ via `apply_narrow`/`unapply_narrow` | correspondence: GtkBuilder `<setter>` has no Ruby equivalent. All eight properties are set, and `unapply_narrow` restores all eight — which the `.ui` gets for free and the port has to get right by hand. **Unverified**: `Adwaita::BreakpointCondition.parse` and `add_breakpoint` were never exercised |
| window geometry | `.ui` 600×300, overridden by the GSettings binding (640×480) | `Settings#apply_to` applies 640×480 | note: identical at runtime; the port never carries the `.ui`'s 600×300, which upstream never reaches either |
| 360×294 size request | ✓ | ✓ | parity |
| `on_menu_popup` | `window.py:157`: `if self.timer_screen.get_visible_child() == self.main_menu.get_parent()` — `GtkOverlay` has no `get_visible_child`, so upstream's F10 handler raises | `if main_stack.visible_child_name == TIMER then main_menu.popup` | substitution: the port implements the behaviour upstream intended. Recorded, and worth reporting upstream |
| frame-clock callbacks | two `add_tick_callback` registrations in `link_state_machine`, **plus** one per timer in `Timer.running=` | one per running timer, in `Timer#running=` | correspondence; upstream's second registration is redundant. **Unverified**: `Gtk::Widget#add_tick_callback`'s block arity in ruby-gnome was never exercised |

Stylesheet: every class attached here (`title-1`, `pill`, `suggested-action`,
`transparent`, `white`, `black`, `image-button`, `circular`, `osd`, `large`,
`linked`) matches upstream's attachment site, and the app-namespaced ones
(`transparent`, `white`, `black`, `large`) have byte-identical rules.
Messages: 16 upstream in this unit, 16 present as bare literals, **0 marked**.
**gap**.
Driven: not run. Rendered: not run.

## Unit: primary menu — `src/gtk/window.ui` `<menu>` → `lib/chess_clock/primary_menu.rb`

| Item | Up × | Port × | Text | Verdict |
|---|---:|---:|:-:|---|
| sections | 3 | 3 | — | parity |
| items | 5 | 5 | ✗ | parity on structure and on all five action names; all five labels unmarked, mnemonic underscores preserved |

## Unit: shortcuts window — `src/gtk/help-overlay.ui` → `lib/chess_clock/shortcuts_window.rb`

| Item | Up × | Port × | Text | Verdict |
|---|---:|---:|:-:|---|
| `Gtk.ShortcutsWindow` (modal) | 1 | 1 | — | parity. The port keeps a GtkBuilder description, which is correct: `GtkShortcutsWindow` accepts sections only through `GtkBuildable.add_child` |
| `Gtk.ShortcutsSection` (`max-height: 10`) | 1 | 1 | — | parity |
| `Gtk.ShortcutsGroup` | 2 | 2 | ✗ | parity on structure |
| `Gtk.ShortcutsShortcut` | 6 | 6 | ✗ | parity on structure and on all six action names |
| the 8 titles | 8 | 8 | ✗ | **gap**: the XML carries `translatable="yes" context="shortcut window"`, but the port never calls `bindtextdomain`/`textdomain` for any domain, so GtkBuilder resolves these against an unset default domain and they stay English in all 42 languages. These are the only strings in the port that are *marked* — and the marking cannot reach a catalogue |

Note: `Gtk.ShortcutsWindow` is deprecated as of GTK 4.18. Both sides use it, so
there is no parity question; it is a forward risk, not a gap.

## Unit: timer button — `src/timerbutton.py` + `.ui` → `lib/chess_clock/timer_button.rb`

| Widget | Up × | Port × | CSS | Signals | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| `Gtk.Button` subclass | 1 | 1 | ✓ `timerbutton`, `opaque`, `white`/`black`, `running`, `expired`, `inverted` — all six dynamic classes attached at the same conditions | ✓ `clicked`, `on_changed`, `on_white`, `on_black`, `on_active` | ✗ | parity on all four structural axes; the two a11y labels unmarked |
| `Adw.BreakpointBin` | 1 | 1 | — | — | — | parity, 240×130 ✓ |
| `Adw.Breakpoint` `min-width: 600px` | 1 | 1 | — | ✓ `apply`/`unapply` | — | correspondence: upstream's `<setter … property="attributes">0 -1 size 102400</setter>` is GtkBuilder-only Pango syntax; the port builds a real `Pango::AttrList` with `AttrSize(100 × Pango::SCALE)` — the same 102400 — and clears it on unapply. **Unverified**: never exercised |
| `Gtk.Box` | 1 | 1 | — | — | — | parity, forced LTR ✓ |
| `Gtk.Label` | 3 | 3 | ✓ `colon` | — | — | parity; minutes plain, seconds `%02d`, time ceil'd from µs — same rounding as upstream |
| `css_name = "button"` | 1 | 0 | — | — | — | correspondence: `Gtk::Button`'s css name is already `button`, so upstream's call is a no-op the port can omit. Named here because the scan reports it as a `css-name` gap |
| `accessible_role = BUTTON` | 1 | 0 | — | — | — | correspondence: a `Gtk::Button` subclass already has that role |
| `inverted` | GObject property | plain attribute | — | — | — | correspondence: only the window's breakpoint ever sets it, and the port's breakpoint sets it directly |
| a11y label relabelled on colour swap | ✓ | ✓ | — | — | — | present at `timer_button.rb:176`; **unverified** |

## Unit: time control entry — `src/timecontrolentry.py` + `.ui` → `lib/chess_clock/time_control_entry.rb`

| Widget | Up × | Port × | CSS | Signals | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| `Gtk.Box` (root) | 1 | 1 | — | — | — | parity, vertical/6/margins 6 ✓ |
| `Gtk.Grid` | 1 | 1 | — | — | — | parity, 6/6/homogeneous ✓ |
| `Gtk.Button` (presets) | 8 | 8 | ✓ `time-button` ×8 | ✓ `clicked` ×8 | ✗ | parity: all eight labels, all eight (minutes, seconds, increment) triples and all eight grid positions match upstream column-first. Scan reads 1 — they come from `PRESETS`. Eight tooltips unmarked |
| `Gtk.Box` (custom) | 1 | 1 | — | — | — | parity, forced LTR ✓ |
| `Gtk.SpinButton` | 3 | 3 | ✓ `custom-spin` ×3 | ✓ `wrapped`, `output` on seconds | ✗ | parity: ranges 0–999 / 0–59 / 0–999, step 1, page 10, `width-chars 3` and `wrap` on seconds, `%02d` output returning true, carry rule (`> 30` borrows a minute, else carries one). Three tooltips unmarked |
| `Gtk.Label` | 2 | 2 | ✓ `custom-label` ×2 | — | — | parity, `∶` and `+` ✓ |
| `Gtk.Adjustment` ×3 | 3 | 3 | — | ✓ `value-changed` → settings | — | correspondence on the `type` axis: upstream binds GSettings to the `SpinButton`'s `value`, the port binds the adjustment. Same stored keys, same defaults |

`get_control` returns `(minutes × 60 + seconds, increment)` on both sides ✓.

## Units: models — `src/timer.py`, `src/statemachine.py` → five Ruby files

No widgets, so the widget/CSS axes are empty; the behaviour axis is the whole
unit, and it was read line by line.

| Behaviour | Verdict |
|---|---|
| `Timer`: `changed`/`expired`/`alerted`, µs off the monotonic clock, alert at `max(10% of default, 10 s)`, `expired` once on the crossing tick, `increment(inc, force:)` skipping an expired clock | parity |
| `StateMachine`: five states, assignment-not-transition (the hook reads the state it is leaving), five signals with the same argument pairs, `add_a_button`/`add_b_button` wiring the same six connections each, `disconnect_all` undoing all of them including the button `clicked` handlers | parity — and the port disconnects the two button `clicked` handlers that upstream reaches with `disconnect_by_func`, which is the same set |
| idle inhibit: `ApplicationInhibitFlags.IDLE`, `"Game clock running"`, taken on entering a run state from a non-run state and released on start/pause | parity |
| `IncrementStateMachine`: increment at start (forced) and on handover | parity |
| `BronsteinStateMachine`: third `inc_timer`, `min(inc - inc_timer.time, inc)` refund, reset to `inc` per move, stopped on pause | parity |
| `DelayStateMachine`: `delay_timer` holding the main clock, restarted per move, `expired` releasing the clock, stopped on pause | parity |
| GObject-ness | correspondence: both models are plain Ruby objects with the `Signals` mixin instead of `GObject.Object`. `connect` returns an int, `disconnect` takes it, handlers get the emitter first — the three conventions the window depends on. The cost is that `muted` and `inverted` are no longer bindable properties; nothing on either side binds them |
| alert sound | **gap**: upstream plays the freedesktop `dialog-warning` event through `GSound.Context.play_simple` at volume 1. The port shells out to `canberra-gtk-play` when it is on `PATH` and otherwise calls `Gdk::Display#beep`. On a machine without libcanberra's player the user gets a terminal bell instead of the alert sound, which is a different sound, at a different volume, through a different device. GSound has no ruby-gnome binding — that is why this gap is expensive, not why it is closed |

## Summary of gaps

1. Application id changed, detaching the port from every installed file.
2. `app.run([])` discards argv.
3. No `.desktop` file.
4. No D-Bus service file.
5. No AppStream metainfo.
6. No icons — the About window's `application_icon` resolves to nothing.
7. No gschema; settings are a private JSON file.
8. About window: no release notes, no translate url, no contribute url.
9. About window `comments` reworded (`…chess` → `…chess.`).
10. Alert sound is not the freedesktop event.
11. The shortcuts window's eight marked strings can never be translated: no
    textdomain is ever bound.
12. 50 of 50 messages unmarked (see `translation-parity.md`).
13. The gem ships neither `data/` nor `po/` and declares no GTK dependency, so
    an installed `chess-clock` cannot start.
14. Not one unit was rendered or driven, so nothing here is evidence that the
    port runs at all.
