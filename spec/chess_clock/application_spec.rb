# frozen_string_literal: true

require "chess_clock/application"

# Ported from ChessClockApplication in src/main.py: `do_activate` raises the
# existing `active_window` rather than building a second one.
#
# G1 (TP4): a second activation — reachable in a real session through the
# installed .desktop file's `DBusActivatable=true` — used to re-run
# `Window#build` into the same widget tree, corrupting it (a
# `gtk_widget_set_parent` critical and `main_stack.pages.n_items` going from
# 2 to 4). `Application#on_activate` now guards the build behind `@activated`
# so only the first activation builds anything and every later one just
# presents the existing window. That guard was previously verified only by
# hand, in a shell that does not run again (A5) — this pins it as a spec.
RSpec.describe ChessClock::Application do
  # A fresh app id per example: Gio::Application exports an object onto the
  # session bus at a path derived from the id, and a second `register` at the
  # same path within one process raises Gio::IOError::Exists.
  subject(:application) do
    described_class.new(app_id: "eu.fortysixandtwo.chessclock.spec#{object_id}", present: false)
  end

  let(:app) { application.build }

  before do
    app.register
  end

  it "builds the window's two-page stack on the first activation" do
    app.activate
    expect(application.main_window.main_stack.pages.n_items).to eq(2)
  end

  it "does not rebuild the stack on a second activation" do
    app.activate
    app.activate
    expect(application.main_window.main_stack.pages.n_items).to eq(2)
  end

  it "presents the same window object on every activation" do
    app.activate
    first_window = application.main_window
    app.activate
    expect(application.main_window).to equal(first_window)
  end
end
