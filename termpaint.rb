require 'tty-cursor'
require 'pastel'

module TermPaint
  module Border
    attr_reader :border

    def self.included(base)
      base.instance_variable_set('@border', true)
    end

    def border?
      !border.zero?
    end

    def border=(val)
      @border = val ? 1 : 0
    end

    def inner_width
      border? ? width - 2 : width
    end

    def inner_height
      border? ? height - 2 : height
    end

    def inner_to_global_x(inner_x)
      x + inner_x + border
    end

    def inner_to_global_y(inner_y)
      y + inner_y + border
    end

    def cursor_to_inner(inner_x, inner_y)
      TTY::Cursor.move_to(x + inner_x + border, y + inner_y + border)
    end
  end

  class Node
    attr_reader :children
    attr_accessor :id, :parent, :x, :y, :height, :width, :visible

    def initialize(x, y, width, height)
      @x = x
      @y = y
      @width = width
      @height = height
      @visible = true
      yield self if block_given?
    end

    def visible?
      !!@visible
    end

    def focusable?
      false
    end

    def focused?
      throw 'Not implemented'
    end

    def repaint
      return unless visible

      repaint_self
      repaint_children
    end

    def repaint_self
      throw 'Not implemented'
    end

    def changed?
      @changed
    end

    def changed(state = true)
      @changed = state
    end

    def repaint_children
      return if @children.nil?

      @children.each do |child|
        child.paint
      end
    end

    def append_child(child)
      child.parent = self
      @children << child
    end
    alias << append_child

    def local_to_global_x(local_x)
      x + local_x
    end

    def local_to_global_y(local_y)
      y + local_y
    end

    def move_to(x, y)
      @x = x
      @y = y
    end

    def resize_to(width, height)
      @width = width
      @height = height
    end

    def find_by_id(find_id)
      return self if find_id == id

      children.each do |child|
        ret = child.find_by_id(find_id)
        return ret if ret
      end
    end

    def find_focussed
      return self if focused?

      children.each do |child|
        ret = child.find_focussed
        return ret if ret
      end
    end
  end

  module Focusable
    def focusable?
      true
    end
  end

  class Box < Node
    include Border
    attr_accessor :background_color, :border_color, :border_char
    attr_reader :pastel

    def initialize(x, y, width, height, border: true, background_color: :black, border_color: :white, border_char: '#')
      super(x, y, width, height)
      @pastel = Pastel.new
      self.border = border
      @background_color = background_color
      @border_color = border_color
      @border_char = border_char
    end

    def repaint_self
      throw 'No background color' if background_color.nil?
      throw 'No border color' if border_color.nil?
      throw 'Border char must be 1 character long' if border_char.size != 1

      cursor = TTY::Cursor
      print cursor.move_to(x, y)
      printer = pastel.send("on_#{background_color}").send(border_color).detach
      print printer.call(border_char * width) if border?
      inner_height.times do |t|
        print cursor.move_to(x, y + t + 1)
        print printer.call(border_char) if border?
        print printer.call(' ' * inner_width)
        print printer.call(border_char) if border?
      end
      print cursor.move_to(x, y + height - 1) if border?
      print printer.call(border_char * width) if border?
    end
  end

  class TextBox < Box
    TAB_WIDTH = 2
    attr_accessor :text, :scroll_y

    def initialize(...)
      super
      @scroll_y = 0
      @text = ''
    end

    def text_lines
      lines = text.gsub("\t", ' ' * TAB_WIDTH).split("\n")
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
      printer = pastel.send("on_#{background_color}").detach
      text_lines[scroll_y..].each_with_index do |line, idx|
        break if idx >= inner_height

        print cursor_to_inner(0, idx)
        print printer.call(line)
      end
    end
  end

  class Root < Node
    def initialize
      columns = `tput columns`.chomp
      lines = `tput lines`.chomp
      super(0, 0, columns, lines)
    end
  end
end
