# customcontrol.py
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

from gi.repository import Adw, Gtk, GLib, GObject, Gio

from math import ceil

@Gtk.Template(resource_path='/com/clarahobbs/chessclock/timecontrolentry.ui')
class ChessClockTimeControlEntry(Gtk.Box):
    __gtype_name__ = 'ChessClockTimeControlEntry'

    two_zero = Gtk.Template.Child()
    two_one = Gtk.Template.Child()
    five_zero = Gtk.Template.Child()
    five_three = Gtk.Template.Child()
    ten_zero = Gtk.Template.Child()
    ten_five = Gtk.Template.Child()
    thirty_zero = Gtk.Template.Child()
    thirty_twenty = Gtk.Template.Child()

    minutes = Gtk.Template.Child()
    seconds = Gtk.Template.Child()
    increment = Gtk.Template.Child()

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.two_zero.connect("clicked", self.set_control, 2, 0, 0)
        self.two_one.connect("clicked", self.set_control, 2, 0, 1)
        self.five_zero.connect("clicked", self.set_control, 5, 0, 0)
        self.five_three.connect("clicked", self.set_control, 5, 0, 3)
        self.ten_zero.connect("clicked", self.set_control, 10, 0, 0)
        self.ten_five.connect("clicked", self.set_control, 10, 0, 5)
        self.thirty_zero.connect("clicked", self.set_control, 30, 0, 0)
        self.thirty_twenty.connect("clicked", self.set_control, 30, 0, 20)

        self.settings = Gio.Settings(schema_id='com.clarahobbs.chessclock')
        self.settings.bind('custom-control-minutes', self.minutes, 'value',
                           Gio.SettingsBindFlags.DEFAULT)
        self.settings.bind('custom-control-seconds', self.seconds, 'value',
                           Gio.SettingsBindFlags.DEFAULT)
        self.settings.bind('custom-control-increment', self.increment, 'value',
                           Gio.SettingsBindFlags.DEFAULT)

        self.minutes_adj = Gtk.Adjustment.new(self.settings['custom-control-minutes'], 0, 999, 1, 10, 0)
        self.minutes.set_adjustment(self.minutes_adj)

        self.seconds_adj = Gtk.Adjustment.new(self.settings['custom-control-seconds'], 0, 59, 1, 10, 0)
        self.seconds.set_adjustment(self.seconds_adj)
        self.seconds.set_wrap(True)
        self.seconds.connect("wrapped", self.on_seconds_wrapped)
        self.seconds.connect("output", self.on_seconds_output)
        self.on_seconds_output(self.seconds)

        self.increment_adj = Gtk.Adjustment.new(self.settings['custom-control-increment'], 0, 999, 1, 10, 0)
        self.increment.set_adjustment(self.increment_adj)

    def get_control(self):
        return (self.minutes_adj.get_value()*60 + self.seconds_adj.get_value(),
                self.increment_adj.get_value())

    def set_control(self, widget, minutes, seconds, increment):
        self.minutes_adj.set_value(minutes)
        self.seconds_adj.set_value(seconds)
        self.increment_adj.set_value(increment)

    def on_seconds_wrapped(self, widget):
        if widget.get_value() > 30:
            self.minutes_adj.set_value(self.minutes_adj.get_value() - 1)
        else:
            self.minutes_adj.set_value(self.minutes_adj.get_value() + 1)

    def on_seconds_output(self, widget):
        val = int(widget.get_value())
        widget.set_text(f"{val:02d}")
        return True
