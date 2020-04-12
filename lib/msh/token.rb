# frozen_string_literal: true

module Msh
  # A Token is the smallest unit of source code recognized.
  #
  # By definition, they contain a token type, and the accompanying text
  # from the input. We also add useful things such as the line and column
  # numbers, which we use in the print output.
  #
  # With line and column numbers, given a list of tokens, we should be
  # able to reconstruct the orignal input (without comments).
  #
  # ```
  # Token.new :WORD, "echo", 1, 4 #=> [1:4-8][WORD, 'echo']
  # ```
  class Token
    attr_reader :type
    attr_reader :value
    attr_reader :line
    attr_reader :column

    # @param type [Symbol]
    # @param value [String]
    # @param line [Integer]
    # @param column [Integer]
    def initialize type:, value:, line:, column:
      @type = type
      @value = value
      @line = line
      @column = column
    end

    # @return [String]
    def to_s
      "[#{@line}:#{@column}-#{column_end}][#{@type}, '#{@value}']"
    end

    # @param other [Token]
    # @return [bool]
    def == other
      @line == other.line \
        && @column == other.column \
        && @value == other.value \
        && @type == other.type
    end

    # Convenience method to create a new token.
    #
    # ```
    # include Msh::Token::Shortcut
    #
    # verbose = Token.new :WORD, "echo", 1, 4
    # terse = t :WORD, "echo", 1, 4
    # terse == verbose #=> true
    # ```
    module Shortcut
      # @see {Token.new}
      def t type, value, line, column
        Token.new :type => type,
                  :value => value,
                  :line => line,
                  :column => column
      end
    end

    private

    def column_end
      offset = @value.size - 1
      # EOF has length zero, so the print output would be off by one
      # when printing the last column of an EOF token.
      offset = 0 if offset.negative?
      @column + offset
    end
  end
end
