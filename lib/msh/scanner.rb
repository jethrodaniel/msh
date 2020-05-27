# frozen_string_literal: true

module Msh
  # Basically a simple `StringScanner`
  #
  #
  class Scanner
    attr_reader :line, :column, :pos

    def initialize string
      @string = string.freeze
      @pos = 0
      @line = 1
      @column = 1
      @last_column = 1
    end

    # @note advances the scanner head
    # @return [String] the next character, EOF char if at the end of input
    def advance
      raise "pos is less than zero (#{@pos})" if @pos.negative?

      c = @string[@pos]
      @pos += 1

      if c == "\n"
        @line += 1
        @last_column = @column
        @column = 1
      else
        @column += 1
      end

      c || "\0"
    end

    # def backup
    #   if current_char == "\n"
    #     @line -= 1
    #     @column = @last_column
    #   else
    #     @column -= 1
    #   end
    #   @curr -= 1
    #   current_char
    # end

    # FIXME: this is causing an issue with the new scanner class
    # @param n [Integer]
    # @return [String, nil] nth character past the scanner head
    def peek n = 1 # rubocop:disable Naming/MethodParameterName
      start = @pos + 1
      c = @string[start...start + n]
      c.nil? || c.empty? ? "\0" : c
    end

    # @return [Boolean]
    def eof?
      current_char == "\0"
    end

    # @return [String] the character under the scanner head, or EOF if at end
    def current_char
      raise "pos is less than zero (#{@pos})" if @pos.negative?

      @string[@pos].freeze || "\0"
    end
  end
end
