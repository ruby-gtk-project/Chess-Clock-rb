# frozen_string_literal: true

require "gtk4"

require_relative "translation"

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
  # declaratively: GtkShortcutsWindow takes its sections through GtkBuildable's
  # add_child, which GTK exposes to builders only. The description below is
  # upstream's help-overlay.ui.
  #
  # The eight titles are *not* marked `translatable="yes"` the way upstream's
  # .ui marks them, because GtkBuilder resolves such a property through
  # dgettext in C against a domain ruby-gettext has no way to bind. They are
  # looked up here instead, with upstream's `msgctxt "shortcut window"`, and
  # interpolated into the description already translated, so the same .po entry
  # answers for them.
  class ShortcutsWindow
    include Translation

    CONTEXT = "shortcut window"

    # GtkBuilder parses the description as XML, so a translation carrying an
    # ampersand or an angle bracket has to arrive escaped.
    def self.title(msgid)
      p_(CONTEXT, msgid)
        .gsub("&", "&amp;")
        .gsub("<", "&lt;")
        .gsub(">", "&gt;")
    end

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
                  <property name="title">#{title("Game")}</property>
                  <child>
                    <object class="GtkShortcutsShortcut">
                      <property name="title">#{title("New Time Control")}</property>
                      <property name="action-name">win.new</property>
                    </object>
                  </child>
                  <child>
                    <object class="GtkShortcutsShortcut">
                      <property name="title">#{title("Restart Timer")}</property>
                      <property name="action-name">win.restart</property>
                    </object>
                  </child>
                </object>
              </child>
              <child>
                <object class="GtkShortcutsGroup">
                  <property name="title">#{title("General")}</property>
                  <child>
                    <object class="GtkShortcutsShortcut">
                      <property name="title">#{title("Open Main Menu")}</property>
                      <property name="action-name">win.menu</property>
                    </object>
                  </child>
                  <child>
                    <object class="GtkShortcutsShortcut">
                      <property name="title">#{title("Show Shortcuts")}</property>
                      <property name="action-name">win.show-help-overlay</property>
                    </object>
                  </child>
                  <child>
                    <object class="GtkShortcutsShortcut">
                      <property name="title">#{title("Close Window")}</property>
                      <property name="action-name">win.close</property>
                    </object>
                  </child>
                  <child>
                    <object class="GtkShortcutsShortcut">
                      <property name="title">#{title("Quit")}</property>
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
