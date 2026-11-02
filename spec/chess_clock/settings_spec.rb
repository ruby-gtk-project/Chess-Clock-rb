# frozen_string_literal: true

require "tmpdir"

require "chess_clock/settings"

# The only persistence the app has. Upstream gets the round trip for free from
# GSettings; the port writes the file itself, so the round trip is the thing
# most worth pinning.
RSpec.describe ChessClock::Settings do
  subject(:settings) { described_class.new(path: path) }

  around do |example|
    Dir.mktmpdir do |dir|
      @path = File.join(dir, "settings.json")
      example.run
    end
  end

  let(:path) { @path }

  it "starts at the eight gschema defaults" do
    expect(described_class::DEFAULTS.keys.to_h { |key| [key, settings[key]] }).to eq(described_class::DEFAULTS.to_h)
  end

  it "round-trips every key through the file" do
    written = {
      "width"                    => 1024,
      "height"                   => 768,
      "is-maximized"             => true,
      "custom-control-minutes"   => 15,
      "custom-control-seconds"   => 30,
      "custom-control-increment" => 7,
      "control-method"           => 2,
      "muted"                    => true,
    }
    written.each { |key, value| settings[key] = value }
    reread = described_class.new(path: path)
    expect(written.keys.to_h { |key| [key, reread[key]] }).to eq(written)
  end

  it "exposes a named accessor per key, hyphens as underscores" do
    settings.control_method = 1
    expect([settings.control_method, settings["control-method"]]).to eq([1, 1])
  end

  it "falls back to the defaults when the file is not JSON" do
    File.write(path, "{ not json")
    expect(described_class.new(path: path).width).to eq(640)
  end

  describe "#record_geometry" do
    # A maximized window keeps the unmaximized size on file, which is the size
    # the next run should restore when it un-maximizes.
    it "keeps the last unmaximized size when the window is maximized" do
      settings.width = 900
      settings.height = 700
      settings.record_geometry(maximized_window)
      reread = described_class.new(path: path)
      expect([reread.width, reread.height, reread.is_maximized]).to eq([900, 700, true])
    end

    it "records the size of an unmaximized window" do
      settings.record_geometry(unmaximized_window)
      reread = described_class.new(path: path)
      expect([reread.width, reread.height, reread.is_maximized]).to eq([1280, 1024, false])
    end
  end

  def maximized_window = double("window", maximized?: true)

  def unmaximized_window
    double(
      "window",
      maximized?:     false,
      default_width:  1280,
      default_height: 1024,
    )
  end
end
