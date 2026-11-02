# frozen_string_literal: true

require "json"
require "fileutils"

require "gio2"

module ChessClock
  # Settings holds the eight keys of upstream's
  # data/eu.fortysixandtwo.chessclock.gschema.xml, with the same names, types
  # and defaults.
  #
  # Ported from the two `Gio.Settings(schema_id='eu.fortysixandtwo.chessclock')`
  # readers upstream has, in ChessClockWindow.__init__ (src/window.py:67) and
  # ChessClockTimeControlEntry.__init__ (src/timecontrolentry.py:54).
  #
  # The store underneath is GSettings against that schema whenever the schema
  # is installed, so `gsettings get eu.fortysixandtwo.chessclock muted` and the
  # settings portal see exactly what the app sees, and GSettings range-checks
  # and types every write. `rake gschema` compiles the schema into
  # data/schemas, and `rake install:data` installs it under PREFIX; a run with
  # neither — the repo checkout, or a spec — finds no schema and falls back to
  # the JSON file this class used to be, so an uninstalled app still remembers
  # its geometry. #store_kind says which of the two is live.
  #
  # The bind_* methods do what upstream's Gio.Settings.bind calls with
  # SettingsBindFlags.DEFAULT do: the widget starts at the stored value and
  # every change writes straight back.
  class Settings
    SCHEMA_ID = "eu.fortysixandtwo.chessclock"

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

    # GSettings against the installed schema: upstream's store, with upstream's
    # typing, ranges and change notification.
    class SchemaStore
      # nil when no schema of that id is installed, which is the signal to use
      # the file instead. Looking the schema up first matters: constructing a
      # Gio::Settings for an absent schema is a fatal g_error in GLib, not an
      # exception Ruby can catch.
      def self.open(schema_id)
        Gio::SettingsSchemaSource.default&.lookup(schema_id, true).then do |schema|
          if schema
            new(Gio::Settings.new(schema_id))
          end
        end
      end

      def initialize(settings)
        @settings = settings
      end

      def [](key) = @settings[key]

      def []=(key, value)
        @settings[key] = value
      end

      def location = @settings.path
      def kind = :gsettings
    end

    # The fallback for an uninstalled checkout: the same eight keys, the same
    # defaults, in one JSON file under XDG_CONFIG_HOME.
    class FileStore
      def initialize(path)
        @path = path
        @values = DEFAULTS.merge(read)
      end

      def [](key) = @values.fetch(key, DEFAULTS[key])

      def []=(key, value)
        @values[key] = value
        write
        value
      end

      def location = @path
      def kind = :file

      private

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

    # An explicit path asks for the file store by name; without one the schema
    # is preferred and the file is what is left when the schema is absent.
    def initialize(path: nil, schema_id: SCHEMA_ID)
      if path
        @store = FileStore.new(path)
      else
        @store = SchemaStore.open(schema_id) || FileStore.new(default_path)
      end
    end

    def [](key) = @store[key.to_s]

    def []=(key, value)
      @store[key.to_s] = value
    end

    def location = @store.location
    def store_kind = @store.kind

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
      self["is-maximized"] = window.maximized?
      if !window.maximized?
        self["width"] = window.default_width
        self["height"] = window.default_height
      end
    end

    # The equivalent of settings.bind(key, spin_button, "value", DEFAULT): the
    # adjustment behind a spin button, since that is where the port keeps the
    # value the spin button shows.
    def bind_adjustment(key, adjustment)
      adjustment.value = self[key]
      adjustment.signal_connect("value-changed") { |adj| self[key] = adj.value.to_i }
    end

    # The equivalent of settings.bind("control-method", combo_row, "selected", …).
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
  end
end
