# frozen_string_literal: true

require "gtk4"
require "adwaita"

require_relative "settings"
require_relative "style"
require_relative "about_dialog"
require_relative "window"

module ChessClock
  # Application is the application singleton.
  #
  # Ported from ChessClockApplication in src/main.py: two application actions,
  # quit and about, and one window raised on activate. Upstream's style sheets
  # come out of its GResource; here Style installs them on the display as the
  # application starts.
  #
  # House style (see .claude/skills/ruby-gtk): every widget is a memoized
  # method, all configuration lives in its `tap`, assembly happens only in
  # `build`, and the launcher is one expression.
  class Application
    APP_ID = "org.rubygtkproject.ChessClock"

    ACCELERATORS = {
      "quit"  => ["<primary>q"],
      "about" => [],
    }.freeze

    def initialize(app_id: APP_ID, flags: :default_flags, settings: nil, present: true)
      @app_id = app_id
      @flags = flags
      @settings = settings
      @present = present
    end

    def build
      app.tap do |a|
        a.signal_connect("activate") do
          style.load

          ACCELERATORS.each { |name, accelerators| create_action(name, accelerators) }

          main_window.tap do |win|
            win.build
            if @present
              win.present
            end
          end
        end
      end
    end

    def run = app.run([])

    # Adwaita::Application is broken in the Ruby bindings; the application
    # object comes from Gtk and only the window is Adwaita.
    def app
      @app ||= begin
        Adwaita.init
        Gtk::Application.new(@app_id, @flags)
      end
    end

    def main_window = @main_window ||= Window.new(app, settings: settings)
    def settings = @settings ||= Settings.new
    def style = @style ||= Style.new
    def about_dialog = @about_dialog ||= AboutDialog.new

    private

      def create_action(name, accelerators)
        Gio::SimpleAction.new(name).tap do |action|
          action.signal_connect("activate") { activate(name) }
          app.add_action(action)
          app.set_accels_for_action("app.#{name}", accelerators)
        end
      end

      def activate(name)
        case name
        when "quit" then app.quit
        when "about" then about_dialog.present(main_window.window)
        end
      end
  end
end
