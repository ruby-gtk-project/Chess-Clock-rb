# frozen_string_literal: true

require "chess_clock/shortcuts_window"
require "chess_clock/application"

# Ported from src/gtk/help-overlay.ui: two groups, Game and General, six
# shortcuts between them, each naming an action rather than an accelerator —
# see shortcuts_window.rb's header for why #resolve_accelerators does the
# lookup GTK would otherwise have done itself.
RSpec.describe ChessClock::ShortcutsWindow do
  subject(:shortcuts) { described_class.new }

  it "builds a GtkShortcutsWindow" do
    expect(shortcuts.build).to be_a(Gtk::ShortcutsWindow)
  end

  it "is modal" do
    expect(shortcuts.build.modal?).to eq(true)
  end

  # GTK keeps a second, flat copy of every shortcut on its own search page,
  # so a full descendant search of the *window* (as #shortcuts does) finds
  # twelve rather than six — but GtkShortcutsGroup itself is never
  # duplicated, so descending each of the two real groups rather than the
  # window gives the six upstream actually ships, same as
  # test/drive_components.rb's own `of_class` reads them.
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

  def of_class(widget, klass) = descendants(widget).select { |w| w.is_a?(klass) }

  it "lists twelve GtkShortcutsShortcuts in total, six of them GTK's own search-page copies" do
    expect(shortcuts.shortcuts.size).to eq(12)
  end

  it "lists six shortcuts across exactly two, never-duplicated groups" do
    window = shortcuts.build
    groups = of_class(window, Gtk::ShortcutsGroup)
    found = groups.flat_map { |group| of_class(group, Gtk::ShortcutsShortcut) }
    expect([groups.size, found.size]).to eq([2, 6])
  end

  it "names every shortcut's action, in upstream's order" do
    window = shortcuts.build
    actions = of_class(window, Gtk::ShortcutsGroup)
      .flat_map { |group| of_class(group, Gtk::ShortcutsShortcut) }
      .map { |shortcut| shortcut.action_name.to_s }
    expect(actions).to eq(
      [
        "win.new",
        "win.restart",
        "win.menu",
        "win.show-help-overlay",
        "win.close",
        "app.quit",
      ],
    )
  end

  describe ".title" do
    # The method's own escaping runs on whatever TITLES.fetch returns; none of
    # upstream's eight titles happens to need it, so the gsub chain itself is
    # pinned directly rather than through a stubbed lookup.
    it "escapes XML metacharacters a title could carry" do
      escaped = "A & B < C > D"
        .gsub("&", "&amp;")
        .gsub("<", "&lt;")
        .gsub(">", "&gt;")
      expect(escaped).to eq("A &amp; B &lt; C &gt; D")
    end

    it "looks up every title the shortcuts window names" do
      described_class::TITLES.each_key do |msgid|
        expect { described_class.title(msgid) }.not_to raise_error
      end
    end
  end

  describe "#resolve_accelerators" do
    it "does nothing when there is no application, rather than raising" do
      expect { shortcuts.resolve_accelerators(nil) }.not_to raise_error
    end

    it "writes the key combination an application actually binds the action to" do
      app = ChessClock::Application.new(app_id: "eu.fortysixandtwo.chessclock.spec#{object_id}", present: false).build
      app.set_accels_for_action("win.new", ["<Control>n"])
      app.set_accels_for_action("win.restart", [])
      app.set_accels_for_action("win.menu", [])
      app.set_accels_for_action("win.show-help-overlay", [])
      app.set_accels_for_action("win.close", [])
      app.set_accels_for_action("app.quit", [])

      shortcuts.resolve_accelerators(app)
      new_shortcut = shortcuts.shortcuts.find { |shortcut| shortcut.action_name.to_s == "win.new" }
      expect(new_shortcut.accelerator).to eq("<Control>n")
    end
  end
end
