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
    attr_accessor :type, :value, :line, :column

    # @return [Boolean]
    attr_accessor :valid

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
      @valid  = false
    end

    # @return [String]
    def to_s
      lexeme_end = @value.size.zero? ? @column : @column + @value&.size - 1
      value = if @type == :EOF
                # RUBY_ENGINE.include?("mruby") ? '"\x00"' : '"\\u0000"'
                '"\\u0000"'
              else
                @value.inspect
              end
      "[#{@line}:#{@column}-#{lexeme_end}][#{@type}, #{value}]"
    end

    # @param other [Token]
    # @return [bool]
    def == other
      other.is_a?(Token) \
        && @line == other.line \
        && @column == other.column \
        && @value == other.value \
        && @type == other.type \
        && @valid == other.valid
    end

    # @return [Boolean] whether this token is completed and valid
    def valid?
      @valid
    end
  end
end
