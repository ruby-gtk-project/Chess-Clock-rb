# frozen_string_literal: true

require_relative "rb/version"

# The packaging namespace of the chess-clock-rb gem.
#
# The application itself lives under ChessClock (lib/chess_clock.rb), which is
# what exe/chess-clock loads; this file exists so the gem's own name is
# requirable, and so it carries nothing but the version. Requiring it does not
# pull in GTK, which is what lets the plain-Ruby parts of the suite run without
# a display or the gtk4 gem.
module Chess
  module Clock
    module Rb
    end
  end
end
