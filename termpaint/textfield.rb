module TermPaint
  class TextField < Node
    TAB_WIDTH = 2
    attr_reader :text, :scroll_x, :cursor_pos

    def initialize(**kwargs)
      kwargs[:height] = 1
      kwargs[:border] = false
      super(**kwargs)
      @text = ''
      @cursor_pos = 0
      @scroll_x = 0
    end

    def focused?
      true # TODO
    end

    def text=(new_text)
      @text = new_text
      @scroll_x = tail_scroll_x
      repaint
    end

    def scroll_x=(scroll)
      @scroll_x = scroll
      repaint
    end

    def cursor_pos=(new_pos)
      return if new_pos.negative? || new_pos > text_line.length - 1

      @cursor_pos = new_pos
      repaint
    end

    def tail_scroll_x
      [text_line.length - width + 1, 0].max
    end

    def text_line
      text.gsub("\t", ' ' * TAB_WIDTH).gsub("\n", ' ') + ' '
    end

    def displayed_text
      text_line[scroll_x..scroll_x + width - 1]
    end

    def cursor_in_display?
      (scroll_x..scroll_x + width).include?(cursor_pos)
    end

    def cursor_pos_in_display
      return unless cursor_in_display?

      cursor_pos - scroll_x
    end

    def repaint_self
      super
      return if scroll_x > text_line.length

      printer = create_painter
      print cursor_to_inner(0, 0)

      out_text = displayed_text

      if cursor_in_display? && focused?
        print printer.call(out_text[0...cursor_pos_in_display])
        print Pastel.new.inverse(out_text[cursor_pos_in_display])
        print printer.call(out_text[cursor_pos_in_display + 1..])
      else
        print printer.call(displayed_text)
      end
    end
  end
end
