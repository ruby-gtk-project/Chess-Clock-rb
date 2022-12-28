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
from gi.repository import Gtk, Gio

from .timerbutton import ChessClockTimerButton

@Gtk.Template(resource_path='/com/clarahobbs/chessclock/window.ui')
class ChessClockWindow(Adw.ApplicationWindow):
    __gtype_name__ = 'ChessClockWindow'

    white_timer = Gtk.Template.Child()
    black_timer = Gtk.Template.Child()

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.create_action('new', self.on_new_action, ['<primary>n'])
        self.create_action('restart', self.on_restart_action, ['<primary>r'])

    def on_new_action(self, widget, _):
        """Callback for the app.new action."""
        print('win.new action activated')

    def on_restart_action(self, widget, _):
        """Callback for the app.restart action."""
        print('win.restart action activated')

    def create_action(self, name, callback, shortcuts=None):
        """Add a window action.

        Args:
            name: the name of the action
            callback: the function to be called when the action is
              activated
            shortcuts: an optional list of accelerators
        """
        action = Gio.SimpleAction.new(name, None)
        action.connect("activate", callback)
        self.add_action(action)
        if shortcuts:
            self.get_application().set_accels_for_action(f"win.{name}", shortcuts)
