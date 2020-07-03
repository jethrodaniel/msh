# frozen_string_literal: true

require "msh/parsers"

class TokenStream
  attr_accessor :pos

  def initialize lexer
    @lexer = lexer
    @tokens = []
    @pos = 0
    @in_word = false
  end

  # we use this to get around discarding whitespace
  def in_word?
    @in_word
  end

  def peek
    if @pos == @tokens.size
      t = @lexer.next_token
      t = @lexer.next_token while %i[SPACE COMMENT].include?(t.type)
      @tokens << t.dup
      @in_word = @tokens.last.type == :WORD
    end

    @tokens[@pos]
  end

  def next
    token = peek
    @pos += 1
    token
  end
end

class Node
  attr_reader :type, :children

  def initialize type, children
    @type = type
    @children = children
  end

  def to_s indent = 0
    if children.size == 1 && children.first.is_a?(String)
      "#{' ' * indent}s(:#{type}, #{children.first.inspect})"
    else
      ch = children.map do |c|
        if c.is_a? Node
          "\n#{c.to_s(indent + 2)}"
        else
          "\n#{' ' * (indent + 2)}#{c}"
        end
      end.join(", ")

      if ch == ""
        "#{' ' * indent}s(:#{type})"
      else
        "#{' ' * indent}s(:#{type}, #{ch})"
      end
    end
  end
end

module Msh
  module Parsers
    module Peg
      class Base
        attr_reader :token_stream

        def initialize token_stream
          @token_stream = token_stream
        end

        def pos
          @token_stream.pos
        end

        def reset index
          @token_stream.pos = index
        end

        def consume *types
          token = @token_stream.peek
          return @token_stream.next if types.include?(token.type)

          nil
        end

        def s type, *children
          Node.new type, children
        end
      end
    end
  end
end
