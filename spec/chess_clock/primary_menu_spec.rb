# frozen_string_literal: true

require "chess_clock/primary_menu"

# Ported from the <menu id="primary_menu"> at the end of src/gtk/window.ui:
# three sections — the two game actions, the mute toggle on its own, then
# help and about — each item an action name window.rb or application.rb
# installs, in upstream's order.
RSpec.describe ChessClock::PrimaryMenu do
  subject(:menu) { described_class.new }

  def items(model, section)
    submenu = model.get_item_link(section, "section")
    (0...submenu.n_items).map do |index|
      [
        submenu.get_item_attribute_value(index, "label", "s"),
        submenu.get_item_attribute_value(index, "action", "s"),
      ]
    end
  end

  it "builds three sections" do
    expect(menu.build.n_items).to eq(3)
  end

  it "puts the new-game and restart actions first, in that order" do
    built = menu.build
    expect(items(built, 0)).to eq(
      [
        ["_New Time Control", "win.new"],
        ["_Restart Timer", "win.restart"],
      ],
    )
  end

  it "puts the mute toggle alone in the second section" do
    built = menu.build
    expect(items(built, 1)).to eq([["_Mute Alert Sound", "win.muted"]])
  end

  it "puts shortcuts and about last, in that order" do
    built = menu.build
    expect(items(built, 2)).to eq(
      [
        ["_Keyboard Shortcuts", "win.show-help-overlay"],
        ["_About Chess Clock", "app.about"],
      ],
    )
  end

  it "memoizes the built model across calls to #build" do
    expect(menu.build).to equal(menu.build)
  end
end
