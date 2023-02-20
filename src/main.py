# main.py
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

import sys
import gi

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')

from gi.repository import Gtk, Gio, Adw
from .window import ChessClockWindow


class ChessClockApplication(Adw.Application):
    """The main application singleton class."""

    def __init__(self):
        super().__init__(application_id='com.clarahobbs.chessclock',
                         flags=Gio.ApplicationFlags.FLAGS_NONE)
        self.create_action('quit', self.on_quit, ['<primary>q'])
        self.create_action('about', self.on_about_action)

    def do_activate(self):
        """Called when the application is activated.

        We raise the application's main window, creating it if
        necessary.
        """
        win = self.props.active_window
        if not win:
            win = ChessClockWindow(application=self)
        win.present()

    def on_quit(self, *args):
        self.quit()

    def on_about_action(self, widget, _):
        """Callback for the app.about action."""
        about = Adw.AboutWindow(transient_for=self.props.active_window,
                                application_name='Chess Clock',
                                application_icon='com.clarahobbs.chessclock',
                                issue_url='https://gitlab.gnome.org/World/chess-clock/-/issues/new',
                                developer_name='Clara Hobbs 🏳️‍⚧️🌹🏳‍🌈',
                                version='0.3.1',
                                developers=['Clara Hobbs‍️', 'gregorni'],
                                artists=['Brage Fuglseth'],
                                copyright='© 2022–2023 the Chess Clock contributors\n\nThis application comes with absolutely no warranty. See the <a href="https://www.gnu.org/licenses/gpl-3.0.html">GNU General Public License, version 3 or later</a> for details.')
        about.present()

    def create_action(self, name, callback, shortcuts=None):
        """Add an application action.

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
            self.set_accels_for_action(f"app.{name}", shortcuts)


def main(version):
    """The application's entry point."""
    app = ChessClockApplication()
    return app.run(sys.argv)
