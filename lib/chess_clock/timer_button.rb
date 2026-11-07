# frozen_string_literal: true

require "gtk4"
require "adwaita"

require_relative "translation"
require_relative "accessible_label"

module ChessClock
  # TimerButton is one player's clock face: the whole half of the window they
  # tap to hand the move over.
  #
  # Ported from src/timerbutton.py and src/gtk/timerbutton.ui. The face is
  # three labels — minutes, a U+2236 ratio colon, seconds — in a box that is
  # always laid out left to right, because a clock reads the same in an RTL
  # locale. A BinLayout on the button keeps that box centred at whatever size
  # the half gets.
  #
  # The CSS classes carry the state, exactly as upstream's stylesheet expects:
  #
  #   white / black  which side this clock belongs to, swapped by awbb/abbw
  #   running        the clock currently counting down (a heavier weight)
  #   expired        out of time (a red background)
  #   inverted       rotated 180°, for the player sitting opposite in portrait
  #
  # The BreakpointBin is what jumps the digits to 100pt once the button is wide
  # enough to hold them, which upstream does with the same breakpoint setting
  # Pango size attributes on the three labels.
  #
  # timerbutton.py:53-55 calls set_css_name("button") and
  # set_accessible_role(BUTTON) on its own GType, because a GtkWidget
  # subclass otherwise takes a css name derived from its own class. Neither
  # call has a counterpart here, and none is needed: subclassing Gtk::Button
  # itself (rather than Gtk::Widget, as upstream's ChessClockTimerButton
  # does) keeps both the "button" css node name and the BUTTON accessible
  # role, inherited rather than restated. Verified live: a built TimerButton's
  # `css_name` is "button" and `accessible_role` is `:button`.
  class TimerButton < Gtk::Button
    include Translation
    include AccessibleLabel

    FONT_SIZE = 100
    LARGE_CONDITION = "min-width: 600px"
    MINIMUM_WIDTH = 240
    MINIMUM_HEIGHT = 130
    COLON = "∶"

    # timerbutton.py:58/63's on_white/on_black calls, reached whenever the
    # sides swap (the awbb/abbw signals).
    ACCESSIBLE_LABELS = {
      white: _("Player white timer"),
      black: _("Player black timer"),
    }.freeze

    # window.ui:214/225's static `<accessibility><property name="label"
    # context="a11y">` on the a_timer/b_timer children — the name a freshly
    # built window gives each clock face before any swap has happened. Same
    # English text as ACCESSIBLE_LABELS, different msgctxt, so both need their
    # own catalogue entry.
    INITIAL_ACCESSIBLE_LABELS = {
      white: p_("a11y", "Player white timer"),
      black: p_("a11y", "Player black timer"),
    }.freeze

    attr_reader :inverted

    def initialize(colour)
      super()
      @colour = colour
      @inverted = false
      self.layout_manager = Gtk::BinLayout.new
      self.hexpand = true
      add_css_class("timerbutton")
      add_css_class("opaque")
      add_css_class(colour.to_s)
      announce(self, INITIAL_ACCESSIBLE_LABELS.fetch(colour))
    end

    def build
      tap do |button|
        button.child = breakpoint_bin

        breakpoint_bin.tap do |bin|
          bin.child = timer_box
          bin.add_breakpoint(large_breakpoint)

          timer_box.tap do |box|
            box.append(minutes)
            box.append(colon)
            box.append(seconds)
          end

          large_breakpoint.tap do |breakpoint|
            breakpoint.signal_connect("apply") { resize_face(large_attributes) }
            breakpoint.signal_connect("unapply") { resize_face(inherited_attributes) }
          end
        end
      end
    end

    # --- Signal handlers the state machine connects ---------------------------

    # Upstream rounds up, so a clock shows 1:00 for the whole last second
    # rather than 0:59 for most of it, and only shows 0:00 when the time is
    # really gone.
    def on_changed(_timer, time)
      display = ([time, 0].max / 1_000_000.0).ceil
      minutes.label = (display / 60).to_s
      seconds.label = format("%02d", display % 60)
      if time <= 0
        add_css_class("expired")
      else
        remove_css_class("expired")
      end
    end

    def on_white(*_args)
      add_css_class("white")
      remove_css_class("black")
      name_face(:white)
    end

    def on_black(*_args)
      add_css_class("black")
      remove_css_class("white")
      name_face(:black)
    end

    # active is "this button can be tapped", current is "this is the clock that
    # is running"; the running clock also takes the focus, so the keyboard can
    # hand the move over without the pointer.
    def on_active(_machine, active, current)
      self.sensitive = active
      if current
        add_css_class("running")
        grab_focus
      else
        remove_css_class("running")
      end
    end

    # Upstream exposes this as a GObject property so an AdwBreakpoint setter
    # can flip it; here the window's breakpoint calls it directly.
    def inverted=(inverted)
      @inverted = inverted
      if inverted
        add_css_class("inverted")
      else
        remove_css_class("inverted")
      end
    end

    # --- Widgets --------------------------------------------------------------

    def breakpoint_bin
      @breakpoint_bin ||= Adwaita::BreakpointBin.new.tap do |bin|
        bin.width_request = MINIMUM_WIDTH
        bin.height_request = MINIMUM_HEIGHT
      end
    end

    def large_breakpoint
      @large_breakpoint ||= Adwaita::Breakpoint.new(Adwaita::BreakpointCondition.parse(LARGE_CONDITION))
    end

    # LTR whatever the locale: minutes left of seconds is part of reading a
    # clock, not part of reading a sentence.
    def timer_box
      @timer_box ||= Gtk::Box.new(:horizontal, 0).tap do |box|
        box.halign = :center
        box.direction = Gtk::TextDirection::LTR
      end
    end

    def minutes = @minutes ||= Gtk::Label.new("0")

    def colon
      @colon ||= Gtk::Label.new(COLON).tap do |label|
        label.add_css_class("colon")
      end
    end

    def seconds = @seconds ||= Gtk::Label.new("00")

    def large_attributes
      @large_attributes ||= Pango::AttrList.new.tap do |attributes|
        attributes.insert(Pango::AttrSize.new(FONT_SIZE * Pango::SCALE))
      end
    end

    # An empty list, which is how a label goes back to taking its size from
    # the stylesheet.
    def inherited_attributes = @inherited_attributes ||= Pango::AttrList.new

    private

      def resize_face(attributes)
        [minutes, colon, seconds].each { |label| label.attributes = attributes }
      end

    # The face shows digits, so the accessible name has to say whose clock it
    # is; it changes with the colour, because the sides swap between games.
      def name_face(colour)
        announce(self, ACCESSIBLE_LABELS.fetch(colour))
      end
  end
end
