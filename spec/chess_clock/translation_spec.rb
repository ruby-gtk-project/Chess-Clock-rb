# frozen_string_literal: true

require "tmpdir"
require "fileutils"

require "chess_clock/translation"

# TR1: `rake locale` passed `--output-file` to a `MsgFmt` whose option is
# `--output`, so it aborted on the first language and compiled zero of the 42
# `.mo` files — the app rendered in English in every shipped locale. This
# compiles po/de.po exactly the way `rake locale` now does and reads a
# translated string back through ChessClock::Translation's own binding, so a
# regression here is a spec failure rather than something only a fresh audit
# with a display notices.
#
# The lookup is bound and read through `described_class` (a real, stably
# named module) rather than through an RSpec example instance: GetText's
# `ClassInfo.normalize_class` falls back to binding at `Object` scope for any
# receiver whose class name is anonymous, which an example instance's class
# can be, and that would leak this spec's temporary catalogue path into every
# other spec's `_()` lookups for the rest of the process.
RSpec.describe ChessClock::Translation do
  around do |example|
    Dir.mktmpdir do |dir|
      @locale_dir = dir
      example.run
    end
  end

  def compile_de
    require "gettext/tools/msgfmt"
    FileUtils.mkdir_p(File.join(@locale_dir, "de", "LC_MESSAGES"))
    GetText::Tools::MsgFmt.run(
      File.join("po", "de.po"),
      "--output",
      File.join(@locale_dir, "de", "LC_MESSAGES", "#{described_class::TEXTDOMAIN}.mo"),
    )
  end

  it "compiles po/de.po without the gettext gem rejecting the MsgFmt option" do
    expect { compile_de }.not_to raise_error
    expect(File).to exist(File.join(@locale_dir, "de", "LC_MESSAGES", "#{described_class::TEXTDOMAIN}.mo"))
  end

  it "reads a translated string back through the compiled catalogue" do
    compile_de
    described_class.bindtextdomain(described_class::TEXTDOMAIN, path: @locale_dir)
    GetText.locale = "de"
    expect(described_class._("Chess Clock")).to eq("Schachuhr")
  ensure
    GetText.locale = "en"
    described_class.bindtextdomain(described_class::TEXTDOMAIN, path: described_class.locale_path)
  end
end
