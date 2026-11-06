# Component parity — Chess Clock

| | |
|---|---|
| Upstream | `origin/main` @ `775f046` (2026-09-20) |
| Port | `ruby` (round 1 follow-up, this audit) |
| Units with parity | **13 / 18** |
| Verdict | **NOT AT PARITY — 6 open gaps (G3, G4, G5, G9, G10, G12-partial)**. G7 is a recorded substitution, not a gap. G1, G6 and G8 are closed this round (see below); the stray-byte half of G12 (the "Clara Hobbs" credit) is also closed, leaving only the release-notes-version divergence, which is a documented improvement over upstream rather than owed work. |
| Runtime | `nix develop` + `xvfb-run -a`, GTK 4.22.4, ruby 3.4.9; 196 drive checks, 0 failed; 88 specs, 0 failed |

Four axes, all of which must hold for the same component: **count**, **style**
(CSS classes and their rules), **behaviour** (signals and actions), **text**
(translatable strings). The inventory and the unit map are in
`.reports/component-identification.md`.

Nothing in `FINDINGS.md` or `PORTING.md` closes a row below. A binding
limitation is evidence a gap is expensive; it is never evidence it is closed.

## Summary by axis

| Axis | Result |
|---|---|
| Count | ✅ every upstream widget type present; every count difference reconciled by reading (factories, repeaters, the template-root double count) |
| Style | ⚠️ class *sets* identical (20 = 20), both stylesheets reproduced rule-for-rule, `label.colon`'s 17px measured off a live widget — but `css-name` is 1 → 0 (**G6**) |
| Behaviour | ❌ **G3** (no GResource), **G4** (`muted`/`inverted` unbindable), **G5** (alert sound never heard). **G1** (second activation corrupted the window) closed this round. |
| Text | ⚠️ 48 of 50 upstream msgids reached; 2 missing, held as **T1** in `translation-parity.md`. Worse, no catalogue compiles today — **TR1** there |
| Packaging / project | ❌ **G9** (no DOAP, no Flatpak manifest), **G10** (no metadata validation). **G8** (no licence or contributing text) closed this round — `COPYING` and `CONTRIBUTING.md` are now in the tree, copied verbatim from upstream. **G12**'s credits half (the "Clara Hobbs" byte mismatch) is closed; its release-notes-version half is a documented divergence, not owed work. |

## Step 4 — the stylesheet, compared literally

`src/gtk/style.css` (24 rules) against `Style::STYLE`, and
`src/gtk/style-hc.css` (4 rules) against `Style::HIGH_CONTRAST`: the rule
bodies are reproduced verbatim, including the `@brown_5` / `@brown_1` /
`@red_4` / `@red_3` / `@light_1` Adwaita named colours and the two
`:focus-visible` outline hex literals. Every class the upstream sheets define
is attached to a widget by the port, and every class the port attaches has a
rule — on both sides, or in GTK/libadwaita itself (`pill`,
`suggested-action`, `image-button`, `circular`, `osd`, `linked`, `title-1`).

Two differences, and only the second is a gap:

1. **Who loads them.** Upstream never loads either sheet: `AdwApplication`
   picks them up from the resource base path. `Style#install` adds them to the
   display by hand, and `apply_high_contrast` watches
   `Adwaita::StyleManager#notify::high-contrast` to swap the variant in. A
   correspondence — the rendered result is the same — but it is hand-written
   where upstream gets it free, which is the **G3** consequence.
2. **`css-name`.** `timerbutton.py:54` calls `set_css_name("button")`, so
   upstream's selector surface includes the element name. `grep -rn
   'css_name\|accessible_role' lib/` returns nothing. **G6**.

The high-contrast swap itself could not be driven: the portal that drives
`Adwaita::StyleManager#high-contrast` is absent on this display. Only the
sheet's parsing and the watcher's installation were exercised, which is why
**G6** is reported against style rather than style being called clean.

## Per-unit comparison

### `src/main.py` → `lib/chess_clock/application.rb`

| Upstream | Port | |
|---|---|---|
| `Adw.Application` subclass | `Gtk::Application` + `Adwaita.init` | correspondence; the two conveniences it costs are **G3** |
| `create_action('quit', …, ['<primary>q'])` | `ACCELERATORS["quit"]`, `application.rb:30` | ✅ driven |
| `create_action('about', …)` | `ACCELERATORS["about"]`, `application.rb:31` | ✅ driven |
| `do_activate`: `win = active_window; if not win: win = Window(app); win.present()` | `on_activate`, `application.rb`: builds once, presents the existing window on every later activation | parity (**G1** closed) |
| `on_about_action` → `Adw.AboutWindow.new_from_appdata` | `Adwaita::AboutDialog`, fields hand-set | **G3**, **G7** |
| stylesheets via the resource base path | `Style#load` by hand | **G3** |

**G1 is closed this round.** `Application#build` now connects `activate` to a
single `on_activate` method that builds the window and installs the style and
app-level actions only the first time through, guarded by `@activated`; every
later activation presents the existing window instead. Re-ran the same drive
that found the bug:

```ruby
app = ChessClock::Application.new(present: false); a = app.build
a.register(nil); a.activate; a.activate
```

No `duplicate child name in GtkStack` warning, no
`gtk_widget_set_parent` critical, and `main_window.main_stack.pages.n_items ==
2`. The path is still reachable in the shipped app the same way —
`data/…desktop.in:10`'s `DBusActivatable=true` and the installed
`data/…service.in` mean a second launch or a D-Bus activation runs this
handler — but it now raises the existing window rather than building a second
widget tree inside it.

### `src/window.py` + `src/gtk/window.ui` → `lib/chess_clock/window.rb`

| Widget | Up × | Port × | CSS | Signals / actions | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| `Adw.ApplicationWindow` | 1 | 1 | — | ✅ | ✅ `_("Chess Clock")` | parity |
| `Gtk.Stack` | 1 | 1 | — | ✅ `slide-left-right` | — | parity |
| `Gtk.WindowHandle` | 1 | 1 | — | — | ✅ `p_("a11y", "Select time controls")` | parity |
| `Adw.ToolbarView` + `Adw.HeaderBar` | 1 + 1 | 1 + 1 | — | — | — | parity |
| `Gtk.ScrolledWindow` | 1 | 1 | — | ✅ `vadjustment` reset on `win.new` | — | parity |
| `Gtk.Label` (welcome ×2) | 2 | 2 | ✅ `title-1` | — | ✅ both | parity |
| `Adw.PreferencesGroup` / `Row` | 1 / 1 | 1 / 1 | — | ✅ `activatable=false` | — | parity |
| `Adw.ComboRow` | 1 | 1 | — | ✅ `notify::selected` → `control-method` | ✅ title + 3 items | parity |
| `Gtk.Button` (start) | 1 | 1 | ✅ `pill`, `suggested-action` | ✅ `clicked` | ✅ | parity |
| `Gtk.Overlay` | 1 | 1 | — | ✅ 6 overlays | — | parity |
| `Gtk.Box` (timer, linked) | 1 | 1 | ✅ `linked`, homogeneous | ✅ orientation flipped by the breakpoint | — | parity |
| `Gtk.Revealer` | 1 | 1 | — | ✅ `crossfade`, `overflow visible` | — | parity |
| `Adw.HeaderBar` (timer) | 1 | 1 | ✅ `transparent` | — | — | parity |
| `Gtk.EventControllerMotion` | 1 | 1 | — | ✅ `enter`, `motion`, `leave` — all three driven | — | parity |
| `Gtk.WindowControls` | 3 | 3 | ✅ `white`/`black`, swapped on `awbb`/`abbw` | ✅ | — | parity |
| `Gtk.MenuButton` | 1 | 1 | ✅ `image-button`, `circular`, `osd` | ✅ menu model; `win.menu` pops it | ✅ `_("Main Menu")` | parity |
| `Gtk.Button` (play/pause) | 1 | 1 | ✅ + `large` | ✅ `clicked`; icon swaps | ✅ `_("Toggle Pause")` | parity |
| `Adw.Breakpoint` | 1 | 1 | — | ✅ all 7 setters reproduced in `apply_narrow`/`unapply_narrow`, driven both ways | — | parity |

Actions: 7 upstream (`win.new`, `win.restart`, `win.close`, `win.menu`,
`win.muted`, plus libadwaita's `win.show-help-overlay` and `app.*`) against 7
in the port, every accelerator asserted installed and every action activated.
Messages: 11 upstream, 11 in the port.

Three correspondences, located rather than excused:

- `play_pause` is connected once to a closure that reads `@state_machine` at
  click time (`window.rb:166`), where upstream reconnects it in
  `link_state_machine`/`unlink_state_machine`. Same behaviour across a machine
  swap; driven.
- `on_menu_popup` tests `main_stack.visible_child_name == TIMER`
  (`window.rb:227`) where `window.py:252` compares
  `timer_screen.get_visible_child()` against `main_menu.get_parent()`. The
  port's condition is the behaviour upstream intends (F10 opens the menu only
  on the screen the menu button is on); driven on both pages.
- Upstream's `window.ui` sets `default-width 600` / `default-height 300` and
  then immediately binds both to GSettings, whose defaults are 640/480, so the
  bound values win. `Settings#apply_to` reaches the same first-run geometry;
  driven (restore and record).

One upstream defect the port does **not** reproduce, and should not:
`window.py:154-178` builds and adds the `muted` action twice. The port adds it
once (`window.rb:503`).

### `src/timerbutton.py` + `src/gtk/timerbutton.ui` → `lib/chess_clock/timer_button.rb`

| Widget | Up × | Port × | CSS | Signals | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| `Gtk.Button` (subclass) | 1 | 1 | ✅ `timerbutton`, `opaque`, `white`/`black`, `running`, `expired`, `inverted` — all driven | ✅ `clicked` wired by the machine | ✗ | **gap G6 + T1** |
| `Adw.BreakpointBin` | 1 | 1 | — | ✅ 240×130 | — | parity |
| `Adw.Breakpoint` (`min-width: 600px`) | 1 | 1 | — | ✅ `apply`/`unapply` → real `Pango::AttrList`, driven on a 700px face and back | — | parity |
| `Gtk.Box` | 1 | 1 | — | ✅ forced `TextDirection::LTR` | — | parity |
| `Gtk.Label` | 3 | 3 | ✅ `colon` | — | — | parity |
| `set_css_name("button")` | 1 | — | ✅ inherited | — | — | parity (**G6** closed) |
| `set_accessible_role(BUTTON)` | 1 | — | — | ✅ inherited | — | parity (**G6** closed) |

`on_changed`'s ceil-to-the-second rounding, `expired` on and off, `running`,
and the colour swap are all driven in `drive_countdown.rb`.

**G6 is closed.** `timerbutton.py:53-55` sets the css name to `button` and the
accessible role to `Gtk.AccessibleRole.BUTTON` on its own GType, because
upstream's `ChessClockTimerButton` subclasses `Gtk.Widget` directly.
`timer_button.rb`'s `TimerButton` subclasses `Gtk::Button` instead, and a
`GtkWidget` subclass keeps its parent's css node name and accessible role
unless it overrides them — so both come for free. Verified live: a built
`TimerButton`'s `css_name` is `"button"` and `accessible_role` is `:button`.
Documented in `timer_button.rb`'s class comment rather than left to be
re-discovered as a gap.

Two smaller text/style notes, both real differences:

- `timerbutton.ui:12,24` ship `4` and `20` as the labels' initial text;
  `timer_button.rb:154,162` ship `0` and `00`. Both are replaced on the first
  `changed`, so this is only the first frame — but the first frame differs.
- The `inverted` property: upstream exposes it as a `GObject.Property` so the
  window's breakpoint can set it declaratively. Here `apply_narrow` calls
  `a_timer.inverted =` by hand. Same effect, driven; the lost bindability is
  **G4**.

### `src/timecontrolentry.py` + `src/gtk/timecontrolentry.ui` → `lib/chess_clock/time_control_entry.rb`

| Widget | Up × | Port × | CSS | Signals | Text | Verdict |
|---|---:|---:|---|---|:-:|---|
| `Gtk.Box` (root, LTR custom box) | 2 | 2 | — | ✅ | — | parity |
| `Gtk.Grid` | 1 | 1 | — | ✅ 4×2, homogeneous, spacing 6 | — | parity |
| `Gtk.Button` (presets) | 8 | 8 | ✅ `time-button` | ✅ all 8 `clicked` driven and read back | ✅ 8 tooltips | parity |
| `Gtk.SpinButton` | 3 | 3 | ✅ `custom-spin` | ✅ `wrapped`, `output` | ✅ 3 tooltips | parity |
| `Gtk.Label` | 2 | 2 | ✅ `custom-label` | — | — | parity |
| `Gtk.Adjustment` | 3 | 3 | — | ✅ bound to GSettings, upper 999/59/999 | — | parity |

Grid placement is column-first on both sides (`1+0`/`2+1` in column 0, …), the
seconds wrap carries and borrows a minute, and `%02d` output is driven.
Messages: 11 upstream, 11 in the port. **Full parity.**

### `src/gtk/window.ui` `<menu>` → `lib/chess_clock/primary_menu.rb`

3 sections, 5 items, 5 action names, 5 mnemonic-bearing msgids — all equal, all
driven (the menu is opened from `win.menu` and each item's label and action
read back). **Full parity.**

### `src/gtk/help-overlay.ui` → `lib/chess_clock/shortcuts_window.rb`

1 window, 1 section (`max-height 10`, `modal`), 2 groups, 6 shortcuts in
upstream's order, 8 titles under `msgctxt "shortcut window"`, every key
combination resolved (Ctrl+N, Ctrl+R, F10, Ctrl+?, Ctrl+W, Ctrl+Q) and driven.

Correspondence: the window is built from a GtkBuilder string rather than
declaratively, because `GtkShortcutsWindow` accepts sections only through
GtkBuildable's `add_child`. The string is upstream's `.ui`, with the titles
pre-translated in Ruby instead of carrying `translatable="yes"`. Located:
`shortcuts_window.rb:37-104`. **Full parity on all four axes**, with the
extraction caveat held as **T2**.

### `src/main.py` (`on_about_action`) → `lib/chess_clock/about_dialog.rb`

| Upstream | Port | |
|---|---|---|
| `Adw.AboutWindow` | `Adwaita::AboutDialog` | **G7** — recorded substitution, not a gap |
| `new_from_appdata(resource, "0.6.0")` | 16 hand-set properties | **G3**, **G12** |
| `set_developers([4])`, `set_artists([1])`, `set_translator_credits(_("translator-credits"))` | ✅ all three, driven | ✅ |

**G7** is the substitution the skill permits — `AdwAboutWindow` is deprecated
in libadwaita 1.6 in favour of `AdwAboutDialog`, so upstream is the one behind.
Recorded, not silent.

Two real differences inside it, neither of which **G3** excuses:

- `main.py:56` passes `"0.6.0"` as the release-notes version; `about_dialog.rb:43`
  hardcodes `"0.6.2"`, and sets a `version` property upstream never sets. The
  About window therefore shows a different release's notes than upstream's
  does. The port is arguably more current; upstream is still the spec, so this
  is a divergence and is written down rather than quietly preferred.
- `main.py:67` lists `'Clara Hobbs‍️'` (the name plus a stray
  ZWJ + VS16 pair, U+200D U+FE0F — an upstream editing artifact, reproduced
  rather than cleaned up). Closed this round: `about_dialog.rb`'s
  `DEVELOPERS` now carries `"Clara Hobbs‍️"`, byte for byte.

### `src/timer.py` → `lib/chess_clock/timer.rb`

3 signals, the monotonic-clock countdown, `changed` on every tick/reset/
increment, `expired` once on the tick that reaches zero, `alerted` once at
`max(default/10, 10s)`, and `increment(force:)` leaving an expired clock alone.
17 specs plus a real game driven to zero in `drive_countdown.rb`.
**Full parity.**

Correspondence, located: upstream installs both timers' frame-clock callbacks
in `window.py:196-197`; here each `Timer` installs its own in `running=`
(`timer.rb:49`) and removes it by returning false. Nothing on either side
tests either shape.

### `src/statemachine.py` → `state_machine.rb` + three subclasses

5 states, 5 signals, both clicks, `on_pause_clicked`'s four-way toggle, the
idle inhibit/uninhibit with upstream's untranslated `"Game clock running"`
reason, `disconnect_all` across a machine swap, and all three time-control
rules (Fischer increment, Bronstein refund capped at the delay, simple delay
released by the delay timer's `expired`). 42 specs plus three drive scripts.
**Full parity on behaviour.**

**G4** sits on top of it: `Timer` and `StateMachine` are plain Ruby objects, so
`muted` and `inverted` are not GObject properties and no `Gio::Settings.bind`,
`AdwBreakpoint` setter or `GtkExpression` can reach them. Admitted in
`signals.rb:10-19`. Behaviour still owed: **the mute state and the inverted
face can be driven by anything that binds a GObject property, as upstream's
breakpoint does.**

### `src/statemachine.py` (`GSound.Context`) → `lib/chess_clock/alert_sound.rb`

**G5.** The alert has never been heard. `GObjectIntrospection::Loader.load("GSound", …)`
raises `TypelibNotFound` in this dev shell, so `available?` is `false` in every
run to date and every alert takes a fallback. `Context#init`'s arity and
whether the loader marshals a Ruby Hash into `play_simple`'s `GHashTable`
remain unverified. Driven: the `alerted` path fires, the muted path plays
nothing, and `win.muted` flips both ways — but the sound itself is the thing
upstream does, and it is unproven. Behaviour still owed: **a player with ten
seconds left hears the `dialog-warning` event at volume 1.**

### `data/…gschema.xml` → `lib/chess_clock/settings.rb`

8 keys, 8 names, 8 types, 8 defaults, all equal. `SchemaStore` opens
`Gio::Settings` against upstream's schema id when the compiled schema is
installed, so `gsettings get eu.fortysixandtwo.chessclock muted` and the port
agree; `FileStore` is the uninstalled-checkout fallback. The three
`Gio.Settings.bind` calls upstream makes have equivalents in `apply_to`,
`bind_adjustment` and `bind_combo_row`, all driven, including a re-read from a
fresh store and a corrupt file falling back to the defaults.
**Full parity.** (The earlier **G2** — a JSON file standing in for GSettings —
is closed by `settings.rb:45-70`.)

### `src/gtk/style.css`, `style-hc.css` → `lib/chess_clock/style.rb`

See Step 4. Rules reproduced; loading hand-written (**G3**); high-contrast
swap undrivable here.

### `src/chess-clock.in` → `exe/chess-clock`

`signal.SIG_DFL` for SIGINT ✅, textdomain bound before any marked constant
loads ✅, one-expression launch ✅. Missing: the
`Gio.Resource.load(...)._register()` pair — **G3**.

## Project-level gaps

**G3 — no GResource.** Upstream compiles `window.ui`, `timecontrolentry.ui`,
`timerbutton.ui`, `help-overlay.ui`, `style.css`, `style-hc.css` and the
metainfo into `chess-clock.gresource` and lets GTK and libadwaita find them.
The port has no bundle, so: the stylesheets are Ruby heredocs
(`style.rb:23-148`), the shortcuts window is a Ruby heredoc
(`shortcuts_window.rb:44`), and the About window's fields are retyped
(`about_dialog.rb:29-73`). Admitted in all three files. Behaviour still owed:
**editing `data/…metainfo.xml.in` or a stylesheet changes what the app shows,
without anyone retyping it into Ruby.**

**G8 — closed.** `COPYING` (upstream's GPLv3 text, copied verbatim) and
`CONTRIBUTING.md` (upstream's guide, copied verbatim) are now both in the
tree root, so a user who opens the About window's licence page or unpacks the
gem finds the same GPL-3 text and contribution guide upstream ships, and
`about_dialog.rb:57`'s Contribute link now points at a document the port also
carries locally.

**G9 — no project metadata.** `chess-clock.doap` and
`eu.fortysixandtwo.chessclock.json` (the Flatpak manifest) have no counterpart,
so the port cannot be built as a Flatpak or listed as a GNOME module the way
upstream can. Behaviour still owed: **the port can be built and installed as a
Flatpak from its own manifest.**

**G10 — no metadata validation.** `data/meson.build` runs
`desktop-file-validate` on the desktop entry and `appstream-util validate` on
the metainfo at build time; the Rakefile has `locale`, `gschema` and
`install:data` and no validation task at all (`grep -n
'desktop-file-validate\|appstream-util\|appstreamcli' Rakefile` → nothing).
`po/meson.build`'s `.pot` regeneration also has no counterpart, which is what
hides **T2**. Behaviour still owed: **a malformed desktop entry or metainfo
file fails the port's build the way it fails upstream's.**

## Rows this audit closed since the last ledger

| Was | Now |
|---|---|
| **G2** JSON file instead of GSettings | closed — `SchemaStore`, driven |
| **G11** the port has never been rendered or driven | closed — 196 checks, 29 screenshots, 0 failures |
| **G1** second activation corrupted the window | closed — `on_activate` guards the build, re-driven: `n_items == 2` after a double activate |
| **G6** `css_name`/`accessible_role` missing on the clock face | closed — both are inherited from `Gtk::Button`, verified live, not a code change |
| **G8** no licence text, no contributing guide | closed — `COPYING` and `CONTRIBUTING.md` added, copied verbatim from upstream |
| **G12** (credits half) the "Clara Hobbs" byte mismatch | closed — the stray ZWJ+VS16 pair is now reproduced |

## What the drive run does not reach, and is therefore not claimed

1. GSound (**G5**) — no typelib in the dev shell.
2. `Gtk::Accessible#update_property` — still
   `NotImplementedError: TODO: in Ruby -> GIArgument(array/C)[interface(enum)](GtkAccessibleProperty)`,
   so names go through LABELLED_BY and the LABEL property upstream sets is
   unasserted.
3. Synthetic key events — accelerators are asserted installed and actions are
   activated; no key is pressed, because the display has no input device.
4. The high-contrast swap — no portal here.
5. Any non-English locale — see `translation-parity.md` **TR1**; it could not
   pass today even if a check asked for it.
