#!/usr/bin/env ruby

require 'tty-cursor'
require 'tty-screen'
require 'pastel'

require_relative 'termpaint/node'
require_relative 'termpaint/textbox'
require_relative 'termpaint/root'
require_relative 'termpaint/textfield'

module TermPaint
  VERSION = '0.0'
end

def ootw
  yield
  print TTY::Cursor.move_to(20, 30)
end
