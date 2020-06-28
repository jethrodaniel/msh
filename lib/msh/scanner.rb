# frozen_string_literal: true

module Msh
  # A minimal `StringScanner` that keeps track of line and column numbers
  class Scanner
    attr_reader :line, :column, :pos

    def initialize string
      @string = string
      @pos = 0
      @line = 1
      @column = 1
      @last_column = 1
      @last_line = 1
      @newlines = {} # 0..12 => q
    end

    # @note advances the scanner head
    # @return [String] the next character, EOF char if at the end of input
    def advance
      raise "pos is less than zero (#{@pos})" if @pos.negative?

      c = @string[@pos]
      @pos += 1

      if c == "\n"
        @newlines[@last_column - 1..@pos] = @line
        @last_line = @line
        @last_column = @column
        @line += 1
        @column = 1
      else
        @column += 1
      end

      c || "\0"
    end

    def backup
      if current_char == "\n"
        @line -= 1
        @column = @last_column
      else
        @column -= 1
      end
      @pos -= 1
      current_char
    end

    # @param nth [Integer]
    # @return [String] nth character past the scanner head
    def peek nth = 1
      start = @pos + 1
      c = @string[start...start + nth]
      c.nil? || c.empty? ? "\0" : c
    end

    # @return [Boolean]
    def eof?
      current_char == "\0"
    end

    # @return [String] the character under the scanner head, or EOF if at end
    def current_char
      @string[@pos] || "\0"
    end

    def reset pos
      raise "pos is less than zero (#{pos})" if pos.negative?
      raise "pos (#{pos}) exceeds source length (#{@string.size})" if pos > @string.size - 1

      @pos = pos
      require 'pry';require 'pry-byebug';binding.pry;nil
      puts

      @line = @newlines[pos]
      @column = pos - @line

      current_char
    end
  end
end
