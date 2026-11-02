# frozen_string_literal: true

require "json"
require "fileutils"

module ChessClock
  # Settings holds the eight keys of upstream's
  # data/eu.fortysixandtwo.chessclock.gschema.xml, with the same names, types
  # and defaults.
  #
  # Upstream reads them through Gio.Settings, which needs the schema compiled
  # and installed into a system glib-2.0/schemas directory before the app will
  # even start. Requiring an install step to run the port from a checkout is
  # worse than the alternative, so the same keys are backed by a small JSON
  # file under XDG_CONFIG_HOME.
  #
  # The bind_* methods stand in for upstream's Gio.Settings.bind calls with
  # SettingsBindFlags.DEFAULT: the widget starts at the stored value and every
  # change writes straight back.
  class Settings
    DEFAULTS = {
      "width"                    => 640,
      "height"                   => 480,
      "is-maximized"             => false,
      "custom-control-minutes"   => 5,
      "custom-control-seconds"   => 0,
      "custom-control-increment" => 0,
      "control-method"           => 0,
      "muted"                    => false,
    }.freeze

    def initialize(path: nil)
      @path = path || default_path
      @values = DEFAULTS.merge(read)
    end

    def [](key) = @values.fetch(key.to_s, DEFAULTS[key.to_s])

    def []=(key, value)
      @values[key.to_s] = value
      write
      value
    end

    def location = @path

    # Named accessors for every key, so callers do not repeat the strings:
    # settings.control_method, settings.muted = true, and so on.
    DEFAULTS.each_key do |key|
      name = key.tr("-", "_")
      define_method(name) { self[key] }
      define_method(:"#{name}=") { |value| self[key] = value }
    end

    # The width/height/is-maximized bindings of upstream's window: the geometry
    # of the previous run is restored, and every later change is recorded.
    def apply_to(window)
      window.set_default_size(self["width"], self["height"])
      if self["is-maximized"]
        window.maximize
      end
      %w[maximized default-width default-height].each do |property|
        window.signal_connect("notify::#{property}") { record_geometry(window) }
      end
    end

    # A maximized window keeps the unmaximized size on file, which is what the
    # next run should restore when it un-maximizes.
    def record_geometry(window)
      @values["is-maximized"] = window.maximized?
      if !window.maximized?
        @values["width"] = window.default_width
        @values["height"] = window.default_height
      end
      write
    end

    # Stands in for settings.bind(key, spin_button, "value", DEFAULT): the
    # adjustment behind a spin button, since that is where the port keeps the
    # value the spin button shows.
    def bind_adjustment(key, adjustment)
      adjustment.value = self[key]
      adjustment.signal_connect("value-changed") { |adj| self[key] = adj.value.to_i }
    end

    # Stands in for settings.bind("control-method", combo_row, "selected", …).
    def bind_combo_row(key, row)
      row.selected = self[key]
      row.signal_connect("notify::selected") { |combo, _| self[key] = combo.selected }
    end

    private

      def default_path
        File.join(config_home, "chess-clock-rb", "settings.json")
      end

      def config_home
        ENV.fetch("XDG_CONFIG_HOME") { File.join(Dir.home, ".config") }
      end

      def read
        if File.exist?(@path)
          parse
        else
          {}
        end
      end

      def parse
        JSON.parse(File.read(@path))
      rescue JSON::ParserError, SystemCallError
        {}
      end

      def write
        FileUtils.mkdir_p(File.dirname(@path))
        File.write(@path, "#{JSON.pretty_generate(@values)}\n")
      end
  end
end
