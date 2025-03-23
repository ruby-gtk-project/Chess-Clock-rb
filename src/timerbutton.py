# timerbutton.py
#
# Copyright 2022-2023 the Chess Clock contributors
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

from gettext import gettext as _

from gi.repository import Adw
from gi.repository import GObject, Gtk, GLib

from math import ceil

@Gtk.Template(resource_path='/eu/fortysixandtwo/chessclock/timerbutton.ui')
class ChessClockTimerButton(Gtk.Button):
    __gtype_name__ = 'ChessClockTimerButton'

    timer_box = Gtk.Template.Child()
    minutes = Gtk.Template.Child()
    seconds = Gtk.Template.Child()

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.set_layout_manager_type(Gtk.BinLayout)
        self.set_css_name("button")
        self.set_accessible_role(Gtk.AccessibleRole.BUTTON)
        self.add_css_class("timerbutton")
        self.timer_box.set_direction(Gtk.TextDirection.LTR)
        self._inverted = False

    def on_changed(self, timer, time):
        disptime = ceil(max(time, 0) / 1_000_000)
        minutes = disptime // 60
        seconds = disptime % 60
        self.minutes.set_label(f"{minutes}")
        self.seconds.set_label(f"{seconds:02d}")
        if time <= 0:
            self.add_css_class("expired")
        else:
            self.remove_css_class("expired")

    def on_white(self, *args):
        self.add_css_class("white")
        self.remove_css_class("black")
        self.update_property([Gtk.AccessibleProperty.LABEL], [_("Player white timer")])

    def on_black(self, *args):
        self.add_css_class("black")
        self.remove_css_class("white")
        self.update_property([Gtk.AccessibleProperty.LABEL], [_("Player black timer")])

    def on_active(self, _, active, current):
        self.set_sensitive(active)
        if current:
            self.add_css_class("running")
            self.grab_focus()
        else:
            self.remove_css_class("running")

    @GObject.Property(type=bool, default=False)
    def inverted(self):
        """Whether to display the button inverted"""
        return self._inverted

    @inverted.setter
    def inverted(self, inv):
        self._inverted = inv
        if inv:
            self.add_css_class("inverted")
        else:
            self.remove_css_class("inverted")
