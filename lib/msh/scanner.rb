# frozen_string_literal: true

module Msh
  # Basically a simple `StringScanner`
  class Scanner
    # @return [Integer] the current line
    attr_reader :line

    # @return [Integer] the current column
    attr_reader :column

    def initialize string
      @string = string
      @pos = 0
      @line = 1
      @column = 1
      @last_column = 1
    end

    # @note advances the scanner head
    # @return [String] the next character, EOF char if at the end of input
    def advance
      c = @string[@pos += 1]

      if c == "\n"
        @line += 1
        @last_column = @column
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

    # @param n [Integer]
    # @return [String, nil] nth character past the scanner head
    def peek n = 1 # rubocop:disable Naming/MethodParameterName
      c = @string[@pos + 1]
      c.empty? ? "\0" : c
    end

    # @return [Boolean]
    def eof?
      current_char == "\0"
    end

    # @return [String] the character under the scanner head, or EOF if at end
    def current_char
      @string[@pos] || "\0"
    end
  end
end
