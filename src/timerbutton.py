# window.py
#
# Copyright 2022 Clara Hobbs 🏳️‍⚧️🌹🏳‍🌈
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

from gi.repository import Adw
from gi.repository import Gtk, GLib

from math import ceil

@Gtk.Template(resource_path='/com/clarahobbs/chessclock/timerbutton.ui')
class ChessClockTimerButton(Gtk.Button):
    __gtype_name__ = 'ChessClockTimerButton'

    minutes = Gtk.Template.Child()
    seconds = Gtk.Template.Child()

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.set_layout_manager_type(Gtk.BinLayout)
        self.set_css_name("button")
        self.set_accessible_role(Gtk.AccessibleRole.BUTTON)
        self.add_css_class("timerbutton")

        self.set_default_control(260, 0)
        self.reset_timer()

        self.last_tick = GLib.get_monotonic_time()
        self.add_tick_callback(self.on_tick, None, None)

        self.connect("clicked", self.on_click, None)

    def set_default_control(self, time, inc):
        """Set the default time and increment"""
        self.default_time = time * 1_000_000
        self.inc = inc * 1_000_000

    def reset_timer(self):
        """Set the timer to the default time"""
        self.time = self.default_time
        self.set_running(False)
        self.set_sensitive(True)
        self.update_label()

    def set_running(self, running):
        self.running = running
        self.set_sensitive(running)
        if running:
            self.add_css_class("running")
            self.last_tick = GLib.get_monotonic_time()
            # Bonus increment
            if self.time > 0:
                self.time += self.inc
        else:
            self.remove_css_class("running")

    def update_label(self):
        disptime = ceil(max(self.time, 0) / 1_000_000)
        minutes = disptime // 60
        seconds = disptime % 60
        self.minutes.set_label(f"{minutes}")
        self.seconds.set_label(f"{seconds:02d}")

    def on_tick(self, widget, _, __, ___):
        if self.running:
            tick = GLib.get_monotonic_time()
            self.time -= tick - self.last_tick
            self.last_tick = tick
            self.update_label()
        if self.time <= 0:
            self.add_css_class("expired")
        else:
            self.remove_css_class("expired")
        self.add_tick_callback(self.on_tick, None, None)

    def on_click(self, widget, _):
        if not self.running and not self.other.running:
            # Set the button that was clicked as black at the start of a game
            self.add_css_class("black")
            self.remove_css_class("white")
            self.other.add_css_class("white")
            self.other.remove_css_class("black")
            self.windowcontrols.add_css_class("black")
            self.windowcontrols.remove_css_class("white")
            self.other.windowcontrols.add_css_class("white")
            self.other.windowcontrols.remove_css_class("black")
        self.other.set_running(not self.other.running)
        self.set_running(not self.other.running)
