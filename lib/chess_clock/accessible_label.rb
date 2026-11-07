# frozen_string_literal: true

require "gtk4"

module ChessClock
  # AccessibleLabel gives a widget an accessible name.
  #
  # Ported from the four places upstream sets one: the
  # `<accessibility><property name="label">` block on `control_chooser` in
  # src/gtk/window.ui, the same block (context "a11y") on the a_timer/b_timer
  # children in that same file (window.ui:214/225), and the two
  # `update_property([Gtk.AccessibleProperty.LABEL], [_("Player white
  # timer")])` calls in ChessClockTimerButton.on_white/on_black
  # (src/timerbutton.py:60-70).
  #
  # `Gtk::Accessible#update_property` cannot be called from Ruby: the
  # introspection loader has no marshaller for a C array of GtkAccessibleProperty,
  # and raises `NotImplementedError: TODO: in Ruby ->
  # GIArgument(array/C)[interface(enum)](GtkAccessibleProperty)` for every
  # argument shape, including bare integers and a single unwrapped enum.
  #
  # So the name is set through the LABELLED_BY relation instead, which is what
  # `gtk_widget_add_mnemonic_label` writes and which GTK's ATContext resolves to
  # the accessible name when no explicit LABEL property is set. The carrier is a
  # Gtk::Label that is never put in the widget tree, so it contributes text to
  # the accessibility tree and nothing to the layout. Replacing a name means
  # dropping the previous carrier from the relation, which is why the carrier per
  # widget is remembered here.
  module AccessibleLabel
    # Names +widget+, replacing whatever this module named it before.
    def announce(widget, label)
      carriers.delete(widget).then do |previous|
        if previous
          widget.remove_mnemonic_label(previous)
        end
      end
      carriers[widget] = Gtk::Label.new(label).tap { |carrier| widget.add_mnemonic_label(carrier) }
    end

    private

      def carriers = @carriers ||= {}
  end
end
