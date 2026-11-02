# frozen_string_literal: true

require "gtk4"
require "adwaita"

require_relative "translation"

module ChessClock
  # TimeControlEntry is the time-control picker on the setup screen: eight
  # preset buttons over three spin buttons for a custom control.
  #
  # Ported from src/timecontrolentry.py and src/gtk/timecontrolentry.ui. The
  # presets do not start a game of their own; each one just fills the three
  # spin buttons in, so a preset is a starting point the player can still
  # adjust. The grid is filled column-first, as upstream's layout properties
  # are: 1+0 and 2+1 share the first column, 5+0 and 5+3 the second, and so on.
  #
  # The three spin buttons are the stored custom control
  # (custom-control-minutes/seconds/increment), so whatever was last set is
  # still there on the next run. Seconds wrap at 59 and carry into the
  # minutes, and are rendered two digits wide, so the pair reads as one clock
  # value rather than as two independent numbers.
  class TimeControlEntry
    include Translation

    PRESETS = [
      { label: "1+0", minutes: 1, seconds: 0, increment: 0, column: 0, row: 0, tooltip: _("One minute per side, plus zero seconds per turn") },
      { label: "2+1", minutes: 2, seconds: 0, increment: 1, column: 0, row: 1, tooltip: _("Two minutes per side, plus one second per turn") },
      { label: "5+0", minutes: 5, seconds: 0, increment: 0, column: 1, row: 0, tooltip: _("Five minutes per side, plus zero seconds per turn") },
      { label: "5+3", minutes: 5, seconds: 0, increment: 3, column: 1, row: 1, tooltip: _("Five minutes per side, plus three seconds per turn") },
      { label: "10+0", minutes: 10, seconds: 0, increment: 0, column: 2, row: 0, tooltip: _("Ten minutes per side, plus zero seconds per turn") },
      { label: "10+5", minutes: 10, seconds: 0, increment: 5, column: 2, row: 1, tooltip: _("Ten minutes per side, plus five seconds per turn") },
      { label: "30+0", minutes: 30, seconds: 0, increment: 0, column: 3, row: 0, tooltip: _("Thirty minutes per side, plus zero seconds per turn") },
      { label: "30+20", minutes: 30, seconds: 0, increment: 20, column: 3, row: 1, tooltip: _("Thirty minutes per side, plus twenty seconds per turn") },
    ].freeze

    MINUTES_LIMIT = 999
    SECONDS_LIMIT = 59
    INCREMENT_LIMIT = 999
    COLON = "∶"
    PLUS = "+"

    def initialize(settings)
      @settings = settings
    end

    def build
      container.tap do |box|
        box.append(preset_grid)
        box.append(custom_control_box)

        preset_grid.tap do |grid|
          PRESETS.each do |preset|
            preset_button(preset).tap do |button|
              grid.attach(
                button,
                preset[:column],
                preset[:row],
                1,
                1,
              )
              button.signal_connect("clicked") { set_control(preset) }
            end
          end
        end

        custom_control_box.tap do |ccb|
          ccb.append(minutes)
          ccb.append(colon)
          ccb.append(seconds)
          ccb.append(plus)
          ccb.append(increment)

          seconds.tap do |spin|
            spin.signal_connect("wrapped") { on_seconds_wrapped }
            spin.signal_connect("output") { on_seconds_output }
          end
        end

        @settings.bind_adjustment("custom-control-minutes", minutes_adjustment)
        @settings.bind_adjustment("custom-control-seconds", seconds_adjustment)
        @settings.bind_adjustment("custom-control-increment", increment_adjustment)
        on_seconds_output
      end
    end

    # The pair the state machines are built from: total main time in seconds,
    # and the increment in seconds.
    def control
      [
        (minutes_adjustment.value * 60) + seconds_adjustment.value,
        increment_adjustment.value,
      ]
    end

    def set_control(preset)
      minutes_adjustment.value = preset[:minutes]
      seconds_adjustment.value = preset[:seconds]
      increment_adjustment.value = preset[:increment]
    end

    # Wrapping down past 0 lands on 59 and borrows a minute; wrapping up past
    # 59 lands on 0 and carries one.
    def on_seconds_wrapped
      if seconds_adjustment.value > 30
        minutes_adjustment.value -= 1
      else
        minutes_adjustment.value += 1
      end
    end

    # Returning true tells GTK the text has been written already, which is what
    # keeps 7 from being shown as "7" next to the minutes.
    def on_seconds_output
      seconds.text = format("%02d", seconds_adjustment.value.to_i)
      true
    end

    # --- Widgets --------------------------------------------------------------

    def container
      @container ||= Gtk::Box.new(:vertical, 6).tap do |box|
        box.margin_top = 6
        box.margin_bottom = 6
        box.margin_start = 6
        box.margin_end = 6
      end
    end

    def preset_grid
      @preset_grid ||= Gtk::Grid.new.tap do |grid|
        grid.halign = :center
        grid.valign = :center
        grid.vexpand = false
        grid.row_spacing = 6
        grid.column_spacing = 6
        grid.column_homogeneous = true
      end
    end

    def preset_button(preset)
      preset_buttons[preset[:label]] ||= Gtk::Button.new.tap do |button|
        button.label = preset[:label]
        button.tooltip_text = preset[:tooltip]
        button.add_css_class("time-button")
      end
    end

    def preset_buttons = @preset_buttons ||= {}

    # LTR whatever the locale, for the same reason as the clock face.
    def custom_control_box
      @custom_control_box ||= Gtk::Box.new(:horizontal, 0).tap do |box|
        box.halign = :center
        box.direction = Gtk::TextDirection::LTR
      end
    end

    def minutes
      @minutes ||= spin_button(minutes_adjustment, _("Main time minutes"))
    end

    def seconds
      @seconds ||= spin_button(seconds_adjustment, _("Main time seconds")).tap do |spin|
        spin.width_chars = 3
        spin.wrap = true
      end
    end

    def increment
      @increment ||= spin_button(increment_adjustment, _("Increment seconds"))
    end

    def colon = @colon ||= custom_label(COLON)
    def plus = @plus ||= custom_label(PLUS)

    def minutes_adjustment
      @minutes_adjustment ||= adjustment("custom-control-minutes", MINUTES_LIMIT)
    end

    def seconds_adjustment
      @seconds_adjustment ||= adjustment("custom-control-seconds", SECONDS_LIMIT)
    end

    def increment_adjustment
      @increment_adjustment ||= adjustment("custom-control-increment", INCREMENT_LIMIT)
    end

    private

      def adjustment(key, upper)
        Gtk::Adjustment.new(
          @settings[key],
          0,
          upper,
          1,
          10,
          0,
        )
      end

    # Vertical, so the +/- sit above and below the number and the three spin
    # buttons read as one large time.
      def spin_button(adjustment, tooltip)
        Gtk::SpinButton.new(adjustment, 1.0, 0).tap do |spin|
          spin.orientation = :vertical
          spin.tooltip_text = tooltip
          spin.add_css_class("custom-spin")
        end
      end

      def custom_label(text)
        Gtk::Label.new(text).tap do |label|
          label.add_css_class("custom-label")
        end
      end
  end
end
