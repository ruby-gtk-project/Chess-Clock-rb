# frozen_string_literal: true

require "gtk4"

module ChessClock
  # ShortcutsWindow is the keyboard shortcuts window behind
  # win.show-help-overlay.
  #
  # Ported from src/gtk/help-overlay.ui: two groups, Game and General, with six
  # shortcuts between them. Each shortcut names an action rather than an
  # accelerator, and GtkShortcutsShortcut asks the application what that action
  # is bound to — so this window shows the accelerators window.rb and
  # application.rb actually install, and cannot drift from them.
  #
  # This one widget is built from a GtkBuilder description rather than
  # declaratively, because it has to be: GtkShortcutsWindow takes its sections
  # through GtkBuildable's add_child, which GTK exposes to builders only. There
  # is no setter, and no public C function, to add a section from code. The
  # description below is upstream's help-overlay.ui.
  class ShortcutsWindow
    UI = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <interface>
        <requires lib="gtk" version="4.0"/>
        <object class="GtkShortcutsWindow" id="help_overlay">
          <property name="modal">True</property>
          <child>
            <object class="GtkShortcutsSection">
              <property name="section-name">shortcuts</property>
              <property name="max-height">10</property>
              <child>
                <object class="GtkShortcutsGroup">
                  <property name="title" translatable="yes" context="shortcut window">Game</property>
                  <child>
                    <object class="GtkShortcutsShortcut">
                      <property name="title" translatable="yes" context="shortcut window">New Time Control</property>
                      <property name="action-name">win.new</property>
                    </object>
                  </child>
                  <child>
                    <object class="GtkShortcutsShortcut">
                      <property name="title" translatable="yes" context="shortcut window">Restart Timer</property>
                      <property name="action-name">win.restart</property>
                    </object>
                  </child>
                </object>
              </child>
              <child>
                <object class="GtkShortcutsGroup">
                  <property name="title" translatable="yes" context="shortcut window">General</property>
                  <child>
                    <object class="GtkShortcutsShortcut">
                      <property name="title" translatable="yes" context="shortcut window">Open Main Menu</property>
                      <property name="action-name">win.menu</property>
                    </object>
                  </child>
                  <child>
                    <object class="GtkShortcutsShortcut">
                      <property name="title" translatable="yes" context="shortcut window">Show Shortcuts</property>
                      <property name="action-name">win.show-help-overlay</property>
                    </object>
                  </child>
                  <child>
                    <object class="GtkShortcutsShortcut">
                      <property name="title" translatable="yes" context="shortcut window">Close Window</property>
                      <property name="action-name">win.close</property>
                    </object>
                  </child>
                  <child>
                    <object class="GtkShortcutsShortcut">
                      <property name="title" translatable="yes" context="shortcut window">Quit</property>
                      <property name="action-name">app.quit</property>
                    </object>
                  </child>
                </object>
              </child>
            </object>
          </child>
        </object>
      </interface>
    XML

    def build = window

    def present(parent)
      window.tap do |win|
        win.transient_for = parent
        win.present
      end
    end

    def window = @window ||= Gtk::Builder.new(string: UI)["help_overlay"]
  end
end
