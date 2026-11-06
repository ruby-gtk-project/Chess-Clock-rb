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
    # Upstream's id, and not a port-specific one: it is simultaneously the
    # GSettings path, the D-Bus well-known name, the .desktop basename and the
    # icon name, so every file under data/ is keyed on it and so is the
    # application_icon the about window asks for.
    APP_ID = "eu.fortysixandtwo.chessclock"

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
        a.signal_connect("activate") { on_activate }
      end
    end

    def run = app.run(ARGV)

    # I did not build this on Adwaita::Application, so the two things that
    # class does for upstream for free — loading style.css and style-hc.css
    # from the resource path, and wiring help-overlay.ui to
    # win.show-help-overlay — are done by hand in Style and Window instead,
    # and will not follow libadwaita if it changes them. I am an idiot who
    # could not make the Ruby binding for it instantiate. See FINDINGS.md.
    # Upstream: `class ChessClockApplication(Adw.Application)`, src/main.py:31.
    # Port: `Gtk::Application.new`, below.
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

      # Upstream: `do_activate` in src/main.py raises `self.props.active_window`
      # when one already exists, and only builds a window the first time
      # through. A second activation — a second launch while the app is
      # already running, which `DBusActivatable=true` in the installed
      # .desktop file makes reachable — must present the existing window
      # rather than build a second widget tree inside it.
      def on_activate
        if @activated
          main_window.present
        else
          @activated = true
          style.load
          ACCELERATORS.each { |name, accelerators| create_action(name, accelerators) }

          main_window.build
          if @present
            main_window.present
          end
        end
      end
  end
end
