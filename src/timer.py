# timer.py
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

from gi.repository import GObject, GLib

MINIMUM_ALERT_TIME = 10_000_000

class ChessClockTimer(GObject.Object):
    __gtype_name__ = 'ChessClockTimer'

    def __init__(self, machine, **kwargs):
        super().__init__(**kwargs)
        self.machine = machine
        self.reset()

    def reset(self):
        """Set the timer to the default time"""
        self.time = self.machine.default_time
        self.emit("changed", self.time)
        self.running = False
        self.is_alerted = False

    @property
    def running(self):
        return self._running

    @running.setter
    def running(self, running):
        if running and not self.running:
            self.last_tick = GLib.get_monotonic_time()
            self.machine.window.add_tick_callback(self.on_tick, None, None)
        self._running = running

    @GObject.Signal(arg_types=(GObject.TYPE_UINT64,))
    def changed(self, *args):
        pass

    @GObject.Signal
    def expired(self, *args):
        pass

    @GObject.Signal
    def alerted(self, *args):
        pass

    def on_tick(self, widget, _, __, ___):
        if self.running:
            prev_time = self.time
            tick = GLib.get_monotonic_time()
            self.time -= tick - self.last_tick
            self.time = max(0, self.time)
            self.last_tick = tick
            self.emit("changed", self.time)
            if self.time <= 0 and prev_time > 0:
                self.emit("expired")
            if self.time <= max(int(self.machine.default_time*0.1), MINIMUM_ALERT_TIME) and not self.is_alerted:
                self.emit("alerted")
                self.is_alerted = True
        return self.running

    def increment(self, inc, force=False):
        if force or self.time > 0:
            self.time += inc
            self.emit("changed", self.time)
