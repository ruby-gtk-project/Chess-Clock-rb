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
from .customcontrol import ChessClockCustomControl
from .statemachine import ChessClockStateMachine, MachineState

@Gtk.Template(resource_path='/com/clarahobbs/chessclock/window.ui')
class ChessClockWindow(Adw.ApplicationWindow):
    __gtype_name__ = 'ChessClockWindow'

    main_stack = Gtk.Template.Child()
    control_chooser = Gtk.Template.Child()
    one_zero = Gtk.Template.Child()
    two_one = Gtk.Template.Child()
    three_zero = Gtk.Template.Child()
    three_two = Gtk.Template.Child()
    five_zero = Gtk.Template.Child()
    five_three = Gtk.Template.Child()
    ten_zero = Gtk.Template.Child()
    ten_five = Gtk.Template.Child()
    fifteen_ten = Gtk.Template.Child()
    thirty_zero = Gtk.Template.Child()
    thirty_twenty = Gtk.Template.Child()
    custom_control = Gtk.Template.Child()

    timer_screen = Gtk.Template.Child()
    windowcontrols_start_l = Gtk.Template.Child()
    windowcontrols_end_l = Gtk.Template.Child()
    play_pause_l = Gtk.Template.Child()
    a_timer_l = Gtk.Template.Child()
    b_timer_l = Gtk.Template.Child()
    windowcontrols_start_p = Gtk.Template.Child()
    windowcontrols_end_p = Gtk.Template.Child()
    play_pause_p = Gtk.Template.Child()
    a_timer_p = Gtk.Template.Child()
    b_timer_p = Gtk.Template.Child()

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.create_action('new', self.on_new_action, ['<primary>n'])
        self.create_action('restart', self.on_restart_action, ['<primary>r'])

        self.state_machine = ChessClockStateMachine(self)
        self.state_machine.add_a_button(self.a_timer_l)
        self.state_machine.add_b_button(self.b_timer_l)
        self.state_machine.add_a_button(self.a_timer_p)
        self.state_machine.add_b_button(self.b_timer_p)

        self.one_zero.connect("clicked", self.on_control, (60, 0))
        self.two_one.connect("clicked", self.on_control, (120, 1))
        self.three_zero.connect("clicked", self.on_control, (180, 0))
        self.three_two.connect("clicked", self.on_control, (180, 2))
        self.five_zero.connect("clicked", self.on_control, (300, 0))
        self.five_three.connect("clicked", self.on_control, (300, 3))
        self.ten_zero.connect("clicked", self.on_control, (600, 0))
        self.ten_five.connect("clicked", self.on_control, (600, 5))
        self.fifteen_ten.connect("clicked", self.on_control, (900, 10))
        self.thirty_zero.connect("clicked", self.on_control, (1800, 0))
        self.thirty_twenty.connect("clicked", self.on_control, (1800, 20))

        self.custom_control.start.connect("clicked", self.on_control, None)

        self.play_pause_l.connect("clicked", self.state_machine.on_pause_clicked, None)
        self.play_pause_p.connect("clicked", self.state_machine.on_pause_clicked, None)
        self.state_machine.connect("pause", self.on_pause)
        self.state_machine.connect("awbb", self.on_awbb)
        self.state_machine.connect("abbw", self.on_abbw)

        self.add_tick_callback(self.state_machine.timer_a.on_tick, None, None)
        self.add_tick_callback(self.state_machine.timer_b.on_tick, None, None)

    def on_new_action(self, widget, _):
        """Callback for the app.new action."""
        self.main_stack.set_visible_child(self.control_chooser)

    def on_restart_action(self, widget, _):
        """Callback for the app.restart action."""
        self.state_machine.state = MachineState.START

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

    def on_control(self, widget, data):
        if data is None:
            data = self.custom_control.get_control()
        self.state_machine.set_time_control(*data)
        self.state_machine.state = MachineState.START
        self.main_stack.set_visible_child(self.timer_screen)

    def on_pause(self, _, active, paused):
        self.play_pause_l.set_sensitive(active)
        self.play_pause_p.set_sensitive(active)
        if paused:
            self.play_pause_l.set_icon_name("media-playback-start-symbolic")
            self.play_pause_p.set_icon_name("media-playback-start-symbolic")
        else:
            self.play_pause_l.set_icon_name("media-playback-pause-symbolic")
            self.play_pause_p.set_icon_name("media-playback-pause-symbolic")

    def on_awbb(self, _):
        self.windowcontrols_start_l.add_css_class("white")
        self.windowcontrols_start_l.remove_css_class("black")
        self.windowcontrols_end_l.add_css_class("black")
        self.windowcontrols_end_l.remove_css_class("white")
        self.windowcontrols_start_p.add_css_class("white")
        self.windowcontrols_start_p.remove_css_class("black")
        self.windowcontrols_end_p.add_css_class("white")
        self.windowcontrols_end_p.remove_css_class("black")

    def on_abbw(self, _):
        self.windowcontrols_start_l.add_css_class("black")
        self.windowcontrols_start_l.remove_css_class("white")
        self.windowcontrols_end_l.add_css_class("white")
        self.windowcontrols_end_l.remove_css_class("black")
        self.windowcontrols_start_p.add_css_class("black")
        self.windowcontrols_start_p.remove_css_class("white")
        self.windowcontrols_end_p.add_css_class("black")
        self.windowcontrols_end_p.remove_css_class("white")
