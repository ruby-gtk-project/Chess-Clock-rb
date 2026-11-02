# frozen_string_literal: true

require "gtk4"
require "adwaita"

module ChessClock
  # Style loads the application stylesheet.
  #
  # Ported from src/gtk/style.css and src/gtk/style-hc.css. Upstream never
  # loads either one itself: both are compiled into the GResource, and GTK
  # picks them up automatically because they sit at gtk/style.css and
  # gtk/style-hc.css under the application's resource prefix.
  #
  # I did not build a GResource, so the two sheets are inlined into this file
  # and installed on the display by hand: an edit to either sheet is an edit to
  # Ruby source, and the high-contrast sheet is loaded by a condition I wrote
  # rather than by GTK — because I am an idiot who skipped the resource
  # bundle. The rules themselves are byte-identical to upstream's.
  # Upstream: gtk/style.css and gtk/style-hc.css in
  # src/chess-clock.gresource.xml.
  # Port: the two heredocs below, loaded in #load. See FINDINGS.md.
  class Style
    STYLE = <<~CSS
      button.large {
        min-width: 48px;
        min-height: 48px;
      }

      .timerbutton {
        font-size: 70px;
        font-feature-settings: "tnum" 1;
        font-weight: 100;
        min-width: 240px;
        border-radius: 0;
      }

      .black {
        color: rgba(255, 255, 255, 0.9);
      }

      .white {
        color: rgba(0, 0, 0, 0.8);
      }

      .black:backdrop {
        color: rgba(255, 255, 255, 0.7);
        transition: color 200ms ease-in;
      }

      .white:backdrop {
        color: rgba(0, 0, 0, 0.6);
        transition: color 200ms ease-in;
      }

      .inverted box {
        transform: rotate(180deg);
      }

      .timerbutton.black {
        background-color: @brown_5;
        filter: opacity(1);
      }

      .timerbutton.white {
        background-color: @brown_1;
        filter: opacity(1);
      }

      .timerbutton.black:backdrop {
        filter: opacity(0.8);
        transition: filter 200ms ease-in;
      }

      .timerbutton.white:backdrop {
        filter: opacity(0.8);
        transition: filter 200ms ease-in;
      }

      .timerbutton.running {
        font-weight: 300;
      }

      .expired {
        color: @light_1;
      }

      .timerbutton.expired.black {
        background-color: @red_4;
      }

      .timerbutton.expired.white {
        background-color: @red_3;
      }

      .timerbutton:focus-visible {
        outline: 2px solid;
        outline-offset: -20px;
      }

      .timerbutton.white:focus-visible {
        outline-color: #1c71d8;
      }

      .timerbutton.black:focus-visible {
        outline-color: #78aeed;
      }

      label.colon {
        min-width: 17px;
      }

      label.custom-label {
        font-size: 3em;
        min-width: 0.75em;
      }

      button.time-button {
        padding-left: 15px;
        padding-right: 15px;
      }

      spinbutton.custom-spin {
        font-size: 3em;
        min-width: 0.75em;
      }

      headerbar.transparent {
        opacity: 0;
      }
    CSS

    HIGH_CONTRAST = <<~CSS
      .timerbutton.black {
        background-color: #242424;
      }

      .timerbutton.white {
        background-color: #fafafa;
      }

      .timerbutton.expired.black {
        background-color: @red_4;
      }

      .timerbutton.expired.white {
        background-color: @red_3;
      }
    CSS

    def self.load(display: nil) = new.load(display: display)

    def load(display: nil)
      (display || Gdk::Display.default).then do |dpy|
        if dpy
          install(dpy)
        end
      end
      self
    end

    def provider
      @provider ||= Gtk::CssProvider.new.tap do |css|
        css.load(string: STYLE)
      end
    end

    def high_contrast_provider
      @high_contrast_provider ||= Gtk::CssProvider.new.tap do |css|
        css.load(string: HIGH_CONTRAST)
      end
    end

    def style_manager = @style_manager ||= Adwaita::StyleManager.default

    private

      def install(display)
        Gtk::StyleContext.add_provider_for_display(display, provider, Gtk::StyleProvider::PRIORITY_APPLICATION)
        style_manager.signal_connect("notify::high-contrast") { apply_high_contrast(display) }
        apply_high_contrast(display)
      end

    # The high-contrast sheet only overrides the four timer-button background
    # colours, so it has to sit above the sheet it overrides.
      def apply_high_contrast(display)
        if style_manager.high_contrast?
          Gtk::StyleContext.add_provider_for_display(
            display,
            high_contrast_provider,
            Gtk::StyleProvider::PRIORITY_APPLICATION + 1,
          )
        else
          Gtk::StyleContext.remove_provider_for_display(display, high_contrast_provider)
        end
      end
  end
end
