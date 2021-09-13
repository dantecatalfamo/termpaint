#!/usr/bin/env ruby

require 'tty-cursor'
require 'pastel'

module TermPaint
  class Node
    attr_reader :children, :position, :border
    attr_accessor :id, :parent, :height, :width, :visible, :x, :y, :background_color, :text_color, :border_color,
                  :border_char

    def initialize(x, y, width, height, position: :relative, border: true, background_color: nil, text_color: nil, border_color: nil, border_char: '█', id: nil)
      @x = x
      @y = y
      @width = width
      @height = height
      self.border = border
      @visible = true
      @children = []
      @position = position
      @background_color = background_color
      @border_color = border_color
      @text_color = text_color
      @border_char = border_char
      @id = id
      yield self if block_given?
    end

    def global_x(offset = 0)
      return x + offset if parent.nil?

      if position == :relative
        x + parent.x + offset
      else
        x + offset
      end
    end

    def global_y(offset = 0)
      return y + offset if parent.nil?

      if position == :relative
        y + parent.y + offset
      else
        y + offset
      end
    end

    def inner_width
      border? ? width - 2 : width
    end

    def inner_height
      border? ? height - 2 : height
    end

    def inner_to_global_x(inner_x)
      global_x + inner_x + border
    end

    def inner_to_global_y(inner_y)
      global_y + inner_y + border
    end

    def cursor_to_inner(inner_x, inner_y)
      TTY::Cursor.move_to(x + inner_x + border, y + inner_y + border)
    end

    def position=(new_position)
      throw 'Illegal position value' unless %i[relative absolute].includes?(new_position)
      @position = new_position
    end

    def border?
      !border.zero?
    end

    def border=(val)
      @border = val ? 1 : 0
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

    def create_painter
      painter = Pastel.new
      painter = painter.send(text_color) if text_color
      painter = painter.send("on_#{background_color}") if background_color
      painter.detach
    end

    def repaint_background
      return if background_color.nil?

      print TTY::Cursor.move_to(global_x, global_y)
      painter = create_painter
      spaces = ' ' * width
      height.times do |h|
        print painter.call(spaces)
        print TTY::Cursor.move_to(global_x, global_y(h))
      end
    end

    def repaint_border
      return unless border?

      throw 'Border character bust be 1 character long' unless border_char.size == 1

      print TTY::Cursor.move_to(global_x, global_y)
      painter = Pastel.new
      painter = painter.send(border_color) if border_color
      painter = painter.detach
      print painter.call(border_char * width)
      inner_height.times do |h|
        print TTY::Cursor.move_to(global_x, global_y(h + 1))
        print painter.call(border_char)
        print TTY::Cursor.forward(inner_width)
        print painter.call(border_char)
      end
      print TTY::Cursor.move_to(global_x, global_y(height - 1))
      print painter.call(border_char * width)
    end

    def repaint
      return unless visible?

      repaint_background
      repaint_border
      repaint_self
      repaint_children
    end

    def repaint_self; end

    def changed?
      @changed
    end

    def changed(state = true)
      @changed = state
    end

    def repaint_children
      return if @children.nil?

      @children.each(&:repaint)
    end

    def append_child(child)
      child.parent = self
      @children << child
    end
    alias << append_child

    def move_to(new_x, new_y)
      @x = new_x
      @y = new_y
    end

    def resize_to(new_width, new_height)
      @width = new_width
      @height = new_height
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

  class TextBox < Node
    TAB_WIDTH = 2
    attr_accessor :text, :scroll_y

    def initialize(...)
      super
      @scroll_y = 0
      @text = ''
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
      printer = create_painter
      text_lines[scroll_y..].each_with_index do |line, idx|
        break if idx >= inner_height

        print cursor_to_inner(0, idx)
        print printer.call(line)
      end
    end
  end

  class Root < Node
    def initialize
      super(0, 0, cols, lines, background_color: :black)
    end

    def trap
      width = cols
      height = lines
    end

    def cols
      `tput cols`.chomp.to_i
    end

    def lines
      `tput lines`.chomp.to_i
    end
  end
end

# TESTING

def textbox
  b = TermPaint::TextBox.new(1, 1, 15, 10, id: :box)
  b.text = "Hello! This is a textbox test.\nPlease edit this text if you want to :^)"
  b
end

def root
  @root ||= TermPaint::Root.new
end

if $0 == __FILE__
  root << textbox
  root.repaint
  print TTY::Cursor.move_to(10, 20)
  Signal.trap('WINCH') do
    root.repaint
    box = root.find_by_id(:box)
    box.text = root.width.to_s
  end
  sleep 10
end
