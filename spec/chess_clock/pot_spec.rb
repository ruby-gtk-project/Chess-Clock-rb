# frozen_string_literal: true

require "tmpdir"

require "gettext/tools/xgettext"

# T2: shortcuts_window.rb used to call `p_(CONTEXT, msgid)` with both
# arguments as local variables, so ruby-gettext's own extractor
# (`rake pot`, `GetText::Tools::XGetText`, lib/gettext/tools/parser/ruby.rb)
# could not see any of the eight `msgctxt "shortcut window"` titles — there
# was no `.pot` regeneration target that reached them at all. This runs the
# same extraction `rake pot` runs, over the real po/POTFILES.in, and asserts
# every one of those eight titles — and the three `msgctxt "a11y"` labels
# T1 closed — comes back out.
#
# This only covers what the gem's Ruby parser can see. po/POTFILES.in also
# names data/eu.fortysixandtwo.chessclock.desktop.in and
# data/eu.fortysixandtwo.chessclock.metainfo.xml.in, whose translatable
# fields (the .desktop Keywords, the metainfo's developer credit and
# screenshot caption) need GNU `msgfmt --desktop`/`msgfmt --xml` to extract;
# that binary is not in this dev shell (see FINDINGS.md), so those three
# msgids are not asserted here.
RSpec.describe "rake pot" do
  let(:potfiles) do
    File.read("po/POTFILES.in").split("\n").map(&:strip).reject { |line| line.empty? || line.start_with?("#") }
  end

  let(:pot) do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "chess-clock.pot")
      GetText::Tools::XGetText.run(*potfiles, "--output", path)
      File.read(path)
    end
  end

  SHORTCUT_TITLES = [
    "Game",
    "New Time Control",
    "Restart Timer",
    "General",
    "Open Main Menu",
    "Show Shortcuts",
    "Close Window",
    "Quit",
  ].freeze

  A11Y_LABELS = [
    "Select time controls",
    "Player white timer",
    "Player black timer",
  ].freeze

  it "extracts every POTFILES.in source without erroring" do
    expect { pot }.not_to raise_error
  end

  it "extracts all eight \"shortcut window\" titles with their context" do
    SHORTCUT_TITLES.each do |title|
      expect(pot).to include(%(msgctxt "shortcut window"\nmsgid "#{title}"\n))
    end
  end

  it "extracts all three \"a11y\" labels with their context" do
    A11Y_LABELS.each do |label|
      expect(pot).to include(%(msgctxt "a11y"\nmsgid "#{label}"\n))
    end
  end
end
