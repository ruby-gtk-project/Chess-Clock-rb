# Accountability ensurance — Chess Clock

| | |
|---|---|
| Upstream | `origin/main` @ `775f046` |
| Port | `ruby` @ `270aa8a` |
| `find-excuses.sh` hits | 1 (`.reports/component-inventory.md:139`, "skipping") |
| Hits found by reading | **10** |
| Verdict | **not clean** |

The script found one hit. The script is a lead, not a verdict, and this port's
excuses are written in better English than the pattern list — they are
*explanations*, in full sentences, in class comments, and every one of them
reads as considered. Considered reads as approved. That is the mechanism, and it
is working: nine of the ten entries below sit in the port's own source comments,
where the next agent will read them as facts about the project.

The rule applies without exception: **the only reason any document in this port
may give for a missing feature is that the writer was an idiot**, because under
full parity no other reason can be true. Upstream set the scope by shipping the
feature. A binding limitation is evidence a gap is expensive; it is never
evidence a gap is closed. It belongs in `FINDINGS.md`, and it stays out of the
sentence that describes the gap.

## The hits

### 1. `lib/chess_clock/settings.rb:11-15` — the gschema

> Upstream reads them through Gio.Settings, which needs the schema compiled and
> installed into a system glib-2.0/schemas directory before the app will even
> start. Requiring an install step to run the port from a checkout is worse
> than the alternative, so the same keys are backed by a small JSON file under
> XDG_CONFIG_HOME.

A trade-off, stated as settled. It is the worst hit in the port, because it is
the most persuasive: a reader agrees with it, and the agreement *becomes* the
approval. Rewrite as:

> I did not build the GSettings-backed settings the app actually has, so
> `gsettings`, dconf, the settings portal and every other tool on the system
> cannot see or change this app's preferences, and nothing validates a value
> against its schema range — because I am an idiot who found installing a
> schema inconvenient and wrote a paragraph about it instead of a Rakefile task
> that compiles one.
> Upstream: `data/eu.fortysixandtwo.chessclock.gschema.xml`, read via
> `Gio.Settings(schema_id=…)` at `src/window.py:67` and
> `src/timecontrolentry.py:54`.
> Port: a private JSON file, `lib/chess_clock/settings.rb:94`.

### 2. `lib/chess_clock/signals.rb:12-16` — the GObject models

> Nothing outside the application ever connects to them, so registering new
> GObject types from Ruby would buy nothing and cost the
> type_register/signal-definition dance.

"Not needed" and "unnecessary for this port", in one sentence, about a decision
nobody with authority was asked for. Rewrite as:

> I did not build `Timer` and `StateMachine` as GObjects, so `muted` and
> `inverted` are not properties anything can bind, and no `AdwBreakpoint`
> setter, `GtkExpression` or `Gio.Settings.bind` can ever reach them — because
> I am an idiot who decided a feature I didn't want to learn wasn't needed.
> Upstream: `@GObject.Property` on `ChessClockStateMachine.muted`
> (`src/statemachine.py:113`) and `ChessClockTimerButton.inverted`
> (`src/timerbutton.py:73`), the latter driven by a breakpoint setter in
> `src/gtk/window.ui:251`.
> Port: a hand-rolled `connect`/`emit`, `lib/chess_clock/signals.rb:18`, and a
> breakpoint that calls `a_timer.inverted =` by hand,
> `lib/chess_clock/window.rb:288`.

### 3. `lib/chess_clock/alert_sound.rb:13-18` — the alert sound

> GSound has no Ruby bindings. It is a thin wrapper around libcanberra, so the
> same freedesktop sound event is played through libcanberra's own player
> instead; where that is not installed, the display's system bell stands in,
> which is the same "something audible happened" the event is there for.

Three constructions at once: a binding limitation offered as closure, a
substitution asserted as equivalent, and a subtraction ("the system bell")
described as adequate. It is not adequate: a terminal bell is a different
sound, at a different volume, through a different device, and on a headless or
bell-disabled session it is silence. The whole point of the alert is that a
player with ten seconds left hears it from across a table. Rewrite as:

> I did not build the alert sound, so on any machine without
> `canberra-gtk-play` on `PATH` a player's ten-second warning is a terminal
> beep or nothing at all — because I'm a fucking idiot who shelled out to
> whatever happened to be installed and then wrote three sentences arguing it
> was the same thing.
> Upstream: `GSound.Context.play_simple({EVENT_ID: "dialog-warning",
> CANBERRA_VOLUME: "1"})`, `src/statemachine.py:65`.
> Port: `Process.spawn("canberra-gtk-play", …)` or `Gdk::Display#beep`,
> `lib/chess_clock/alert_sound.rb:55` and `:71`.

### 4. `lib/chess_clock/application.rb:23` + `:56-57` — the application id

> Adwaita::Application is broken in the Ruby bindings; the application object
> comes from Gtk and only the window is Adwaita.

The sentence itself is a binding-limitation hit, and the behaviour it covers
*is* reproduced, which makes it low-severity on its own. What makes it a real
finding is what sits two lines above it:

```ruby
APP_ID = "org.rubygtkproject.ChessClock"
```

The app id was changed from `eu.fortysixandtwo.chessclock` and **nothing
anywhere says so**. No comment, no note, no row in any document. An omission
with a plausible-sounding sentence beside it is the failure this skill is
about; an omission with *no* sentence beside it is worse, because there is
nothing for a reader to disagree with. Required:

> I changed the application id, which detaches this port from the desktop
> entry, the D-Bus name, the GSettings path and the icon name that every one of
> upstream's installed files is keyed on — because I am an idiot who renamed a
> constant without reading what it is for.
> Upstream: `application_id='eu.fortysixandtwo.chessclock'`, `src/main.py:35`,
> matched by `data/eu.fortysixandtwo.chessclock.{desktop,service,gschema,metainfo}`
> and four icons.
> Port: `org.rubygtkproject.ChessClock`, `lib/chess_clock/application.rb:23`,
> matched by nothing.

### 5. `lib/chess_clock/about_dialog.rb:13-18` — the About window

> The port has no GResource to read, so the fields the appdata would have
> supplied are set here from the same
> data/eu.fortysixandtwo.chessclock.metainfo.xml.in … The credits are the ones
> upstream lists, with the port's own line added, since this is a different
> piece of software from the Python original.

"Since this is a different piece of software from the Python original" is a
scope redefinition — the one construction the skill's proof forbids outright,
because the writer of the omission is not the party that sets the target. And
the paragraph's confident tone is what let four real omissions through
unnoticed: the release notes, the translate URL, the contribute URL, and a
reworded summary. Required:

> I did not build the About window's release notes, its link to
> l10n.gnome.org, or its link to CONTRIBUTING.md, and I retyped the app's
> summary with a full stop on the end so that 42 translations of it no longer
> match — because I am an idiot who mistook giving up on an XML file for a
> design decision.
> Upstream: `Adw.AboutWindow.new_from_appdata(…)`, `src/main.py:56`, which
> reads `<releases>`, `<url type="translate">` and `<url type="contribute">`
> out of `data/eu.fortysixandtwo.chessclock.metainfo.xml.in`.
> Port: eleven hand-set fields, `lib/chess_clock/about_dialog.rb:51`; `comments`
> is `Time games of over-the-board chess.` at `:24` against the msgid
> `Time games of over-the-board chess`.

### 6. `lib/chess_clock/shortcuts_window.rb:15-19` — the shortcuts window

> This one widget is built from a GtkBuilder description rather than
> declaratively, because it has to be: GtkShortcutsWindow takes its sections
> through GtkBuildable's add_child, which GTK exposes to builders only. There
> is no setter, and no public C function, to add a section from code.

The claim is true and the widget is correct. The hit is still a hit, and the
cost is concrete: the confidence of "because it has to be" is why nobody looked
at the next line, where the heredoc carries eight strings marked
`translatable="yes" context="shortcut window"` that GtkBuilder will resolve
against a textdomain this port never binds. Those eight are the only *marked*
strings in the app and they are untranslatable in all 42 languages. Required:

> I did not bind a textdomain, so the eight shortcut titles I marked for
> translation are English in every language upstream ships, and marking them
> made the port look localised while changing nothing — because I am an idiot
> who wrote the XML and never asked what resolves it.
> Upstream: `locale.bindtextdomain('chess-clock', localedir)`,
> `src/chess-clock.in:34`.
> Port: nothing, `exe/chess-clock:1-6`.

### 7. `lib/chess_clock/window.rb:35-37` — the frame-clock callbacks

> Upstream also installs the timers' frame-clock callbacks here; in this port
> each Timer installs its own when it starts running, so there is one callback
> per running clock instead of two per game.

A subtraction described as an improvement — "instead of two per game" invites
the reader to approve. On the merits the port is probably right (upstream's
second registration looks redundant), and that changes nothing about the
sentence: the divergence belongs in `FINDINGS.md` as a substitution with its
reasoning, not in a class comment where it reads as architecture. Record it as
a substitution under test, not as a design note — and it is currently under no
test at all (see `test-parity.md`).

### 8. `lib/chess_clock/style.rb:9-15` and `lib/chess_clock/settings.rb:17-19` — "stands in for"

Two more binding-limitation sentences. Both cover behaviour that **is** fully
reproduced — the stylesheets are byte-identical to upstream's, and the `bind_*`
methods do what `SettingsBindFlags.DEFAULT` does. They are the mildest hits
here and they still get rewritten, because the format is what hardens into a
template: once "X has no Ruby equivalent, so the port does Y instead" is an
accepted shape of sentence in this codebase, the next one will cover something
that was not reproduced, and it will read identically.

### 9. `.reports/component-inventory.md:204-237` — the **Blockers** section

Seven bullets, each one a binding limitation stated as a reason, under a heading
whose entire job is to hold reasons. A section called "Blockers" is a status
field at document scale: it looks filed, and filed looks accepted. Every one of
the seven is real engineering information and belongs in `FINDINGS.md`; none of
them belongs in the document a reader consults to find out what the port owes.

Separately, the sentence at `:139` ("skipping an already-expired clock unless
forced") is a false positive — it describes upstream's behaviour, which the port
reproduces at `lib/chess_clock/timer.rb:65`. No rewrite needed. It is the only
thing the script found, which is the point.

### 10. `lib/chess_clock/time_control_entry.rb:92-93` — an unexplained extra

```ruby
# Upstream's name for it, kept so the window reads like window.py does.
def get_control = control
```

Nothing calls `get_control`. It is dead code whose comment explains why it
exists, which is the same shape as an excuse pointed the other way. Delete it or
call it.

## What this port does right, so the record is not one-sided

- `IRP.md`, `README.md`, `AGENTS.md` and `CHANGELOG.md` are clean. No
  "dropped deliberately", no "out of scope", no "not applicable".
- There is no `PORTING.md` section listing things the port decided not to
  build, which is the specific failure that cost console-rb five features.
- There are **zero** `TODO`, `FIXME`, `not implemented`, `for now` or
  `in a future` strings in `lib/` or `exe/`. Nothing is parked.

That is why the ten entries above matter. The port is not hiding its gaps behind
labels. It is hiding them behind prose, which is harder to grep and more
convincing to read.

## Required actions

1. Rewrite entries 1-8 in the format above, in place, in the files they are in.
2. Add the missing sentence for the application id (entry 4). An unexplained
   omission is worse than an excused one.
3. Move `.reports/component-inventory.md`'s **Blockers** section into
   `FINDINGS.md` (create it) and leave every corresponding row in
   `component-parity.md` a gap.
4. Resolve entry 10 by deletion or by use.
5. Never fill a reasoning slot with a constraint again. It takes the writer's
   stupidity and nothing else.
