# frozen_string_literal: true

require "gio2"

module ChessClock
  # PrimaryMenu is the menu behind the circular button on the timer screen.
  #
  # Ported from the <menu id="primary_menu"> at the end of src/gtk/window.ui:
  # three sections — the two game actions, the mute toggle on its own, then
  # help and about. The mnemonics are upstream's, and the action names are what
  # window.rb and application.rb install, so a menu item that does nothing is
  # a missing action rather than a missing handler.
  class PrimaryMenu
    SECTIONS = [
      [
        ["_New Time Control", "win.new"],
        ["_Restart Timer", "win.restart"],
      ],
      [
        ["_Mute Alert Sound", "win.muted"],
      ],
      [
        ["_Keyboard Shortcuts", "win.show-help-overlay"],
        ["_About Chess Clock", "app.about"],
      ],
    ].freeze

    def build
      menu.tap do |model|
        SECTIONS.each { |items| model.append_section(nil, section(items)) }
      end
    end

    def menu = @menu ||= Gio::Menu.new

    private

      def section(items)
        Gio::Menu.new.tap do |model|
          items.each { |label, action| model.append(label, action) }
        end
      end
  end
end
