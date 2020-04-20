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
  # Token.new.tap do |t|
  #   t.type = :WORD
  #   t.value = "echo"
  #   t.column = 1
  #   t.line = 4
  # end #=> [1:4-8][WORD, 'echo']
  # ```
  class Token
    attr_accessor :type
    attr_accessor :value
    attr_accessor :line
    attr_accessor :column

    # @param opts [Hash<Symbol, Integer>]
    # @option type [Symbol]
    # @option value [String]
    # @option line [Integer]
    # @option column [Integer]
    def initialize opts = {}
      @type   = opts[:type]
      @value  = opts[:value] || "" # so we can `+=` characters to this
      @line   = opts[:line]
      @column = opts[:column]
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
