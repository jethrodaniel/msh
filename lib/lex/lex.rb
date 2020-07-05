# frozen_string_literal: true

# lex/scanner.rb
module Lex
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

    # def reset pos
    #   raise "pos is less than zero (#{pos})" if pos.negative?
    #   raise "pos (#{pos}) exceeds source length (#{@string.size})" if pos > @string.size - 1

    #   @pos = pos

    #   @line = @newlines[pos]
    #   @column = pos - @line

    #   current_char
    # end
  end
end

# lex/token.rb
module Lex
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
        && @type == other.type
    end
  end
end

# lex/lexer.rb
module Lex
  # The lexer breaks down input text into a series of tokens.
  #
  # By definition, a token contains a type (which token), and a value
  # (the matched string). They also usually contain line and column
  # number information, and other metadata as well. See {Lex::Token}.
  #
  # It operates like so:
  #
  # - As long as input is available, grab the next character
  # - Attempt to match a token
  #
  # The match attempt logic is {#next_token}, which is just a a big
  # switch statement on the next character, more or less.
  #
  class Lexer
    attr_reader :line, :column

    # @param input [String]
    def initialize input
      @scanner = Scanner.new input
      @tokens  = []
      @token   = Token.new
    end

    # Run the lexer on the input until we collect all the tokens.
    #
    # @return [Array<Msh::Token>] all tokens in the input
    def tokens
      next_token until @tokens.last&.type == :EOF
      @tokens
    end

    # {Scanner#eof?} but in such a way that you still get true when the next
    # token is an EOF
    #
    # @return [Boolean] whether the last token is *not* an EOF
    def next?
      @tokens.last&.type != :EOF
    end

    def eof?
      !next?
    end

    # @return [Token, nil]
    def current_token
      @tokens.last
    end

    def next_token
      raise Lex::Error, "#next_token is not overriden"
    end

    protected

    def set_token_start
      @token.line = @scanner.line
      @token.column = @scanner.column
    end

    # nils out all of our current token's fields
    #
    # @return [Token]
    def reset_token
      @token.tap do |t|
        t.type   = nil
        t.value  = ""
        t.line   = nil
        t.column = nil
      end
    end

    def reset_and_set_start
      reset_token
      set_token_start
    end

    def advance
      c = @scanner.advance
      @token.value += c
      c
    end

    # @note we've just seen either a ` ` or a `\t`
    def consume_whitespace
      @token.type = :SPACE
      return if @scanner.current_char == "\0"

      while @scanner.current_char == " " ||
            @scanner.current_char == "\t"
        advance
      end
    end
  end
end
