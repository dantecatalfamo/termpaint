module TermPaint
  class TextBox < Node
    TAB_WIDTH = 2
    attr_reader :text, :scroll_y

    def initialize(...)
      super
      @scroll_y = 0
      @text = ''
    end

    def text=(new_text)
      @text = new_text
      repaint
    end

    def scroll_y=(scroll)
      @scroll_y = scroll
      repaint
    end

    def text_lines
      lines = text.to_s.gsub("\t", ' ' * TAB_WIDTH).split("\n")
      split_lines = []
      lines.each do |line|
        if line.length < inner_width
          split_lines << line
          next
        end
        line.scan(/.{1,#{inner_width}}/).each do |piece|
          split_lines << piece
        end
      end
      split_lines
    end

    def repaint_self
      super
      return if scroll_y > text_lines.length

      printer = create_painter
      text_lines[scroll_y..].each_with_index do |line, idx|
        break if idx >= inner_height

        print cursor_to_inner(0, idx)
        print printer.call(line)
      end
    end
  end
end
