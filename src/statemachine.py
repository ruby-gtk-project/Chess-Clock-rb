# statemachine.py
#
# Copyright 2023 the Chess Clock contributors
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: GPL-3.0-or-later

from enum import Enum

import gi
gi.require_version('GSound', '1.0')
from gi.repository import GObject, Gtk, GSound

from .timer import ChessClockTimer


class MachineState(Enum):
    START = 1
    A_RUN = 2
    B_RUN = 3
    A_PAUSE = 4
    B_PAUSE = 5

class ChessClockStateMachine(GObject.Object):
    __gtype_name__ = 'ChessClockStateMachine'

    def __init__(self, window, time, inc, **kwargs):
        super().__init__(**kwargs)
        self.window = window
        self.app = self.window.get_application()
        self.idle_cookie = 0
        self.set_time_control(time, inc)

        self.timer_a = ChessClockTimer(self)
        self.timer_b = ChessClockTimer(self)

        self.handler_ids = []
        self.handler_ids_ta = []
        self.handler_ids_tb = []

        self.state = MachineState.START
        self.sound = GSound.Context()
        self.sound.init()

    def set_time_control(self, time, inc):
        """Set the default time and increment"""
        self.default_time = time * 1_000_000
        self.inc = inc * 1_000_000

    def timer_alerted(self, *args):
        self.sound.play_simple({GSound.ATTR_EVENT_ID: "dialog-warning",
                         GSound.ATTR_CANBERRA_VOLUME: "1"})

    def add_a_button(self, button):
        self.handler_ids.append(self.connect("a_active", button.on_active))
        self.handler_ids.append(self.connect("awbb", button.on_white))
        self.handler_ids.append(self.connect("abbw", button.on_black))
        self.handler_ids_ta.append(self.timer_a.connect("changed", button.on_changed))
        button.connect("clicked", self.on_a_clicked, None)
        self.handler_ids_ta.append(self.timer_a.connect("alerted", self.timer_alerted))

    def add_b_button(self, button):
        self.handler_ids.append(self.connect("b_active", button.on_active))
        self.handler_ids.append(self.connect("awbb", button.on_black))
        self.handler_ids.append(self.connect("abbw", button.on_white))
        self.handler_ids_tb.append(self.timer_b.connect("changed", button.on_changed))
        button.connect("clicked", self.on_b_clicked, None)
        self.handler_ids_tb.append(self.timer_b.connect("alerted", self.timer_alerted))

    def disconnect_all(self):
        for i in self.handler_ids:
            self.disconnect(i)
        self.handler_ids = []
        for i in self.handler_ids_ta:
            self.timer_a.disconnect(i)
        self.handler_ids_ta = []
        for i in self.handler_ids_tb:
            self.timer_b.disconnect(i)
        self.handler_ids_tb = []

    @property
    def state(self):
        return self._state

    @state.setter
    def state(self, state):
        if state == MachineState.START:
            self.to_start()
        elif state == MachineState.A_RUN:
            self.to_a_run()
        elif state == MachineState.B_RUN:
            self.to_b_run()
        elif state == MachineState.A_PAUSE:
            self.to_a_pause()
        elif state == MachineState.B_PAUSE:
            self.to_b_pause()
        self._state = state

    def to_start(self):
        # Reset timers
        self.timer_a.reset()
        self.timer_b.reset()
        # Set buttons active
        self.emit("a_active", True, False)
        self.emit("b_active", True, False)
        # Uninhibit session idle
        if self.idle_cookie:
            self.app.uninhibit(self.idle_cookie)
        self.idle_cookie = 0
        # Deactivate the pause button while the timers are stopped
        self.emit("pause", False, False)

    def to_a_run(self):
        if self.state == MachineState.START:
            # Set A white, B black
            self.emit("awbb")
        self.timer_b.running = False
        self.timer_a.running = True
        # Set buttons active
        self.emit("a_active", True, True)
        self.emit("b_active", False, False)
        if self.state != MachineState.B_RUN:
            # Inhibit session idle
            self.idle_cookie = self.app.inhibit(None,
                Gtk.ApplicationInhibitFlags.IDLE, "Game clock running")
        # Set pause button to show a pause icon
        self.emit("pause", True, False)

    def to_b_run(self):
        if self.state == MachineState.START:
            # Set A black, B white
            self.emit("abbw")
        self.timer_a.running = False
        self.timer_b.running = True
        # Set buttons active
        self.emit("a_active", False, False)
        self.emit("b_active", True, True)
        if self.state != MachineState.A_RUN:
            # Inhibit session idle
            self.idle_cookie = self.app.inhibit(None,
                Gtk.ApplicationInhibitFlags.IDLE, "Game clock running")
        # Set pause button to show a pause icon
        self.emit("pause", True, False)

    def to_a_pause(self):
        self.timer_a.running = False
        self.emit("a_active", False, True)
        # Uninhibit session idle
        if self.idle_cookie:
            self.app.uninhibit(self.idle_cookie)
        self.idle_cookie = 0
        # Set pause button to show a play icon
        self.emit("pause", True, True)

    def to_b_pause(self):
        self.timer_b.running = False
        self.emit("b_active", False, True)
        # Uninhibit session idle
        if self.idle_cookie:
            self.app.uninhibit(self.idle_cookie)
        self.idle_cookie = 0
        # Set pause button to show a play icon
        self.emit("pause", True, True)

    def on_a_clicked(self, widget, _):
        self.state = MachineState.B_RUN

    def on_b_clicked(self, widget, _):
        self.state = MachineState.A_RUN

    def on_pause_clicked(self, widget, _):
        if self.state == MachineState.A_RUN:
            self.state = MachineState.A_PAUSE
        elif self.state == MachineState.B_RUN:
            self.state = MachineState.B_PAUSE
        elif self.state == MachineState.A_PAUSE:
            self.state = MachineState.A_RUN
        elif self.state == MachineState.B_PAUSE:
            self.state = MachineState.B_RUN

    @GObject.Signal(arg_types=(bool, bool))
    def a_active(self, *args):
        pass

    @GObject.Signal(arg_types=(bool, bool))
    def b_active(self, *args):
        pass

    @GObject.Signal(arg_types=(bool, bool))
    def pause(self, *args):
        pass

    @GObject.Signal
    def awbb(self):
        pass

    @GObject.Signal
    def abbw(self):
        pass


class ChessClockIncrementStateMachine(ChessClockStateMachine):
    def to_start(self):
        super().to_start()
        # Add increment
        self.timer_a.increment(self.inc, force=True)
        self.timer_b.increment(self.inc, force=True)

    def to_a_run(self):
        super().to_a_run()
        # Add increment
        if self.state == MachineState.B_RUN:
            self.timer_b.increment(self.inc)

    def to_b_run(self):
        super().to_b_run()
        # Add increment
        if self.state == MachineState.A_RUN:
            self.timer_a.increment(self.inc)


class ChessClockBronsteinStateMachine(ChessClockStateMachine):
    def __init__(self, *args, **kwargs):
        self.default_time = 0
        self.inc_timer = ChessClockTimer(self)
        super().__init__(*args, **kwargs)

    def to_start(self):
        super().to_start()
        # Add increment
        self.timer_a.increment(self.inc, force=True)
        self.timer_b.increment(self.inc, force=True)
        # Reset increment timer
        self.inc_timer.reset()
        self.inc_timer.time = self.inc
        self.inc_timer.running = False

    def to_a_run(self):
        self.inc_timer.running = False
        super().to_a_run()
        # Add increment
        if self.state == MachineState.B_RUN:
            self.timer_b.increment(min(self.inc - self.inc_timer.time, self.inc))
            self.inc_timer.time = self.inc
        self.inc_timer.running = True

    def to_b_run(self):
        self.inc_timer.running = False
        super().to_b_run()
        # Add increment
        if self.state == MachineState.A_RUN:
            self.timer_a.increment(min(self.inc - self.inc_timer.time, self.inc))
            self.inc_timer.time = self.inc
        self.inc_timer.running = True

    def to_a_pause(self):
        self.inc_timer.running = False
        super().to_a_pause()

    def to_b_pause(self):
        self.inc_timer.running = False
        super().to_b_pause()


class ChessClockDelayStateMachine(ChessClockStateMachine):
    def __init__(self, *args, **kwargs):
        self.default_time = 0
        self.delay_timer = ChessClockTimer(self)
        self.delay_timer.connect("expired", self.timer_expired, None)
        super().__init__(*args, **kwargs)

    def timer_expired(self, *args):
        if self.state == MachineState.A_RUN:
            self.timer_a.running = True
        if self.state == MachineState.B_RUN:
            self.timer_b.running = True

    def to_start(self):
        super().to_start()
        # Reset increment timer
        self.delay_timer.reset()
        self.delay_timer.time = self.inc
        self.delay_timer.running = False

    def to_a_run(self):
        self.delay_timer.running = False
        super().to_a_run()
        # Keep A timer paused if the delay hasn't expired
        if self.delay_timer.time > 0:
            self.timer_a.running = False
        # Add increment
        if self.state == MachineState.B_RUN:
            self.delay_timer.time = self.inc
            self.timer_a.running = False
        self.delay_timer.running = True

    def to_b_run(self):
        self.delay_timer.running = False
        super().to_b_run()
        # Keep B timer paused if the delay hasn't expired
        if self.delay_timer.time > 0:
            self.timer_b.running = False
        # Add increment
        if self.state == MachineState.A_RUN:
            self.delay_timer.time = self.inc
            self.timer_b.running = False
        self.delay_timer.running = True

    def to_a_pause(self):
        self.delay_timer.running = False
        super().to_a_pause()

    def to_b_pause(self):
        self.delay_timer.running = False
        super().to_b_pause()
