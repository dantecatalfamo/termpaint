module TermPaint
  class Root < Node
    def initialize
      super(0, 0, cols, lines, background_color: :black)
    end

    def trap
      Signal.trap('WINCH') do
        Thread.new do # Not the greatest
          self.width = cols
          self.height = lines
          repaint
        end
      end
    end

    def cols
      TTY::Screen.cols
    end

    def lines
      TTY::Screen.lines
    end
  end
end
