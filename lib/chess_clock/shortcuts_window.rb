# frozen_string_literal: true

require "gtk4"

require_relative "translation"

module ChessClock
  # ShortcutsWindow is the keyboard shortcuts window behind
  # win.show-help-overlay.
  #
  # Ported from src/gtk/help-overlay.ui: two groups, Game and General, with six
  # shortcuts between them. Each shortcut names an action rather than an
  # accelerator, and the key combination shown beside it is looked up from what
  # that action is bound to — so this window shows the accelerators window.rb
  # and application.rb actually install, and cannot drift from them. Upstream
  # has GTK do that lookup; here #resolve_accelerators does, for the reason
  # written above it.
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
        resolve_accelerators(parent.application)
        win.present
      end
    end

    # GTK turns a GtkShortcutsShortcut's action-name into the key combination
    # shown beside its title in that widget's `root` vfunc, by asking the
    # application what the action is bound to. By the time a Ruby caller holds
    # the window, that has already happened: GtkBuilder roots every child as it
    # parses, when no application is reachable yet, and nothing re-resolves
    # afterwards. Re-assigning action-name, setting the window's application
    # (even as a builder property, so it is in place before the children
    # exist) and setting transient-for all leave every accelerator empty on
    # GTK 4.22, which is where GtkShortcutsWindow is deprecated.
    #
    # So the lookup GTK would have done is done here, out of the same
    # gtk_application_get_accels_for_action, and written to the `accelerator`
    # property — which does reach the label. Without it this window lists six
    # shortcuts and not one key combination, which is most of the point of it.
    def resolve_accelerators(application)
      application.then do |app|
        if app
          shortcuts.each { |shortcut| name_accelerator(app, shortcut) }
        end
      end
    end

    # Every GtkShortcutsShortcut in the window, including the copies GTK keeps
    # on its own search page.
    def shortcuts = descendants(window).grep(Gtk::ShortcutsShortcut)

    def window = @window ||= Gtk::Builder.new(string: UI)["help_overlay"]

    private

      def name_accelerator(application, shortcut)
        application.get_accels_for_action(shortcut.action_name.to_s).then do |accelerators|
          if !accelerators.empty?
            shortcut.accelerator = accelerators.join(" ")
          end
        end
      end

      def descendants(widget)
        [].tap do |found|
          child = widget.first_child
          while child
            found << child
            found.concat(descendants(child))
            child = child.next_sibling
          end
        end
      end
  end
end
