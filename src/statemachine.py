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

from gi.repository import GObject, Gtk

from .timer import ChessClockTimer


class MachineState(Enum):
    START = 1
    A_RUN = 2
    B_RUN = 3
    A_PAUSE = 4
    B_PAUSE = 5

class ChessClockStateMachine(GObject.Object):
    __gtype_name__ = 'ChessClockStateMachine'

    def __init__(self, window, **kwargs):
        super().__init__(**kwargs)
        self.window = window
        self.idle_cookie = 0
        self.set_time_control(260, 0)

        self.timer_a = ChessClockTimer(self)
        self.timer_b = ChessClockTimer(self)

        self.state = MachineState.START

    def set_time_control(self, time, inc):
        """Set the default time and increment"""
        self.default_time = time * 1_000_000
        self.inc = inc * 1_000_000

    def add_a_button(self, button):
        self.connect("a_active", button.on_active)
        self.connect("awbb", button.on_white)
        self.connect("abbw", button.on_black)
        self.timer_a.connect("changed", button.on_changed)
        button.connect("clicked", self.on_a_clicked, None)

    def add_b_button(self, button):
        self.connect("b_active", button.on_active)
        self.connect("awbb", button.on_black)
        self.connect("abbw", button.on_white)
        self.timer_b.connect("changed", button.on_changed)
        button.connect("clicked", self.on_b_clicked, None)

    @property
    def state(self):
        return self._state

    @state.setter
    def state(self, state):
        if state == MachineState.START:
            # Reset timers
            self.timer_a.reset()
            self.timer_b.reset()
            # Add increment
            self.timer_a.increment(self.inc)
            self.timer_b.increment(self.inc)
            # Set buttons active
            self.emit("a_active", True, False)
            self.emit("b_active", True, False)
            # Uninhibit session idle
            if self.idle_cookie:
                self.window.get_application().uninhibit(self.idle_cookie)
            self.idle_cookie = 0
            # Deactivate the pause button while the timers are stopped
            self.emit("pause", False, False)
        elif state == MachineState.A_RUN:
            if self.state == MachineState.START:
                # Set A white, B black
                self.emit("awbb")
            self.timer_b.running = False
            self.timer_a.running = True
            # Add increment
            if self.state == MachineState.B_RUN:
                self.timer_b.increment(self.inc)
            # Set buttons active
            self.emit("a_active", True, True)
            self.emit("b_active", False, False)
            if self.state != MachineState.B_RUN:
                # Inhibit session idle
                self.idle_cookie = self.window.get_application().inhibit(None,
                    Gtk.ApplicationInhibitFlags.IDLE, "Game clock running")
            # Set pause button to show a pause icon
            self.emit("pause", True, False)
        elif state == MachineState.B_RUN:
            if self.state == MachineState.START:
                # Set A black, B white
                self.emit("abbw")
            self.timer_a.running = False
            self.timer_b.running = True
            # Add increment
            if self.state == MachineState.A_RUN:
                self.timer_a.increment(self.inc)
            # Set buttons active
            self.emit("a_active", False, False)
            self.emit("b_active", True, True)
            if self.state != MachineState.A_RUN:
                # Inhibit session idle
                self.idle_cookie = self.window.get_application().inhibit(None,
                    Gtk.ApplicationInhibitFlags.IDLE, "Game clock running")
            # Set pause button to show a pause icon
            self.emit("pause", True, False)
        elif state == MachineState.A_PAUSE:
            self.timer_a.running = False
            self.emit("a_active", False, True)
            # Uninhibit session idle
            if self.idle_cookie:
                self.window.get_application().uninhibit(self.idle_cookie)
            self.idle_cookie = 0
            # Set pause button to show a play icon
            self.emit("pause", True, True)
        elif state == MachineState.B_PAUSE:
            self.timer_b.running = False
            self.emit("b_active", False, True)
            # Uninhibit session idle
            if self.idle_cookie:
                self.window.get_application().uninhibit(self.idle_cookie)
            self.idle_cookie = 0
            # Set pause button to show a play icon
            self.emit("pause", True, True)
        self._state = state

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
