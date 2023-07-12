# window.py
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

from gi.repository import Adw, Gtk, Gio, GLib

from .timerbutton import ChessClockTimerButton
from .timecontrolentry import ChessClockTimeControlEntry
from .statemachine import (ChessClockStateMachine,
                           ChessClockIncrementStateMachine,
                           ChessClockBronsteinStateMachine,
                           ChessClockDelayStateMachine,
                           MachineState)

@Gtk.Template(resource_path='/com/clarahobbs/chessclock/window.ui')
class ChessClockWindow(Adw.ApplicationWindow):
    __gtype_name__ = 'ChessClockWindow'

    main_stack = Gtk.Template.Child()
    control_chooser = Gtk.Template.Child()
    control_chooser_scroll = Gtk.Template.Child()
    custom_control = Gtk.Template.Child()
    method_chooser = Gtk.Template.Child()
    start_game = Gtk.Template.Child()

    timer_screen = Gtk.Template.Child()
    windowcontrols_start = Gtk.Template.Child()
    windowcontrols_start_end = Gtk.Template.Child()
    windowcontrols_end = Gtk.Template.Child()
    headerbar_revealer = Gtk.Template.Child()
    headerbar_motion = Gtk.Template.Child()
    main_menu = Gtk.Template.Child()
    play_pause = Gtk.Template.Child()
    a_timer = Gtk.Template.Child()
    b_timer = Gtk.Template.Child()

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.create_action('new', self.on_new_action, ['<primary>n'])
        self.create_action('restart', self.on_restart_action, ['<primary>r'])
        self.create_action('close', self.on_close, ['<primary>w'])
        self.create_action('menu', self.on_menu_popup, ['F10'])

        mute_action = Gio.SimpleAction(name="muted",
                                        state=GLib.Variant.new_boolean(False))
        mute_action.connect("activate", self.toggle_muted)
        mute_action.connect("change-state", self.change_muted)
        self.add_action(mute_action)

        self.link_state_machine(ChessClockIncrementStateMachine(self, 300, 0))

        settings = Gio.Settings(schema_id="com.clarahobbs.chessclock")
        settings.bind("control-method", self.method_chooser, "selected",
                           Gio.SettingsBindFlags.DEFAULT)
        settings.bind("width", self, "default-width",
                           Gio.SettingsBindFlags.DEFAULT)
        settings.bind("height", self, "default-height",
                           Gio.SettingsBindFlags.DEFAULT)
        settings.bind("is-maximized", self, "maximized",
                           Gio.SettingsBindFlags.DEFAULT)

        self.start_game.connect("clicked", self.on_start_game)

        self.headerbar_motion.connect("enter", self.reveal_headerbar)
        self.headerbar_motion.connect("motion", self.reveal_headerbar)
        self.headerbar_motion.connect("leave", self.hide_headerbar)

    def link_state_machine(self, sm):
        self.state_machine = sm
        self.state_machine.add_a_button(self.a_timer)
        self.state_machine.add_b_button(self.b_timer)

        self.play_pause.connect("clicked", self.state_machine.on_pause_clicked, None)
        self.state_machine.connect("pause", self.on_pause)
        self.state_machine.connect("awbb", self.on_awbb)
        self.state_machine.connect("abbw", self.on_abbw)

        self.a_tick = self.add_tick_callback(self.state_machine.timer_a.on_tick, None, None)
        self.b_tick = self.add_tick_callback(self.state_machine.timer_b.on_tick, None, None)

    def unlink_state_machine(self):
        self.state_machine.disconnect_all()
        self.a_timer.disconnect_by_func(self.state_machine.on_a_clicked)
        self.b_timer.disconnect_by_func(self.state_machine.on_b_clicked)

        self.play_pause.disconnect_by_func(self.state_machine.on_pause_clicked)
        self.state_machine.disconnect_by_func(self.on_pause)
        self.state_machine.disconnect_by_func(self.on_awbb)
        self.state_machine.disconnect_by_func(self.on_abbw)
        self.remove_tick_callback(self.a_tick)
        self.remove_tick_callback(self.b_tick)

    def on_new_action(self, widget, _):
        """Callback for the app.new action."""
        self.main_stack.set_visible_child(self.control_chooser)
        self.control_chooser_scroll.get_vadjustment().set_value(0)
        self.headerbar_revealer.set_reveal_child(True)

    def on_restart_action(self, widget, _):
        """Callback for the app.restart action."""
        self.state_machine.state = MachineState.START

    def toggle_muted(self, action, _):
        """Connection of mute stateful action with activate signal."""
        state = action.get_state()
        self.state_machine.muted = not state.get_boolean()
        action.change_state(GLib.Variant.new_boolean(self.state_machine.muted))

    def change_muted(self, action, new_state):
        """Connection of mute stateful action with change-state signal."""
        action.set_state(new_state)

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

    def on_close(self, *args):
        self.close()

    def on_menu_popup(self, *args):
        if self.timer_screen.get_visible_child() == self.main_menu.get_parent():
            self.main_menu.activate()

    def on_start_game(self, widget):
        data = self.custom_control.get_control()
        self.unlink_state_machine()
        selected = self.method_chooser.get_selected()
        if selected == 0:
            self.link_state_machine(ChessClockIncrementStateMachine(self, *data))
        elif selected == 1:
            self.link_state_machine(ChessClockBronsteinStateMachine(self, *data))
        elif selected == 2:
            self.link_state_machine(ChessClockDelayStateMachine(self, *data))
        self.state_machine.state = MachineState.START
        self.main_stack.set_visible_child(self.timer_screen)
        self.headerbar_revealer.set_reveal_child(False)

    def on_pause(self, _, active, paused):
        self.play_pause.set_sensitive(active)
        if paused:
            self.play_pause.set_icon_name("media-playback-start-symbolic")
        else:
            self.play_pause.set_icon_name("media-playback-pause-symbolic")

    def on_awbb(self, _):
        self.windowcontrols_start.add_css_class("white")
        self.windowcontrols_start.remove_css_class("black")
        self.windowcontrols_start_end.add_css_class("white")
        self.windowcontrols_start_end.remove_css_class("black")
        self.windowcontrols_end.add_css_class("black")
        self.windowcontrols_end.remove_css_class("white")

    def on_abbw(self, _):
        self.windowcontrols_start.add_css_class("black")
        self.windowcontrols_start.remove_css_class("white")
        self.windowcontrols_start_end.add_css_class("black")
        self.windowcontrols_start_end.remove_css_class("white")
        self.windowcontrols_end.add_css_class("white")
        self.windowcontrols_end.remove_css_class("black")

    def reveal_headerbar(self, *args):
        self.headerbar_revealer.set_reveal_child(True)

    def hide_headerbar(self, *args):
        self.headerbar_revealer.set_reveal_child(False)
