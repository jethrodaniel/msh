# frozen_string_literal: true

# Adapted from the PEG blog posts by the great Guido van Rossum (2019)
#
# - [index](https://medium.com/@gvanrossum_83706/peg-parsing-series-de5d41b2ed60)

# grammar: rule+ ENDMARKER
# rule: NAME ':' alternative ('|' alternative)* NEWLINE
# alternative: item+
# item: NAME | STRING
# module Msh

require "msh/core_extensions"
require "msh/scanner"
require "msh/lexer"

Scanner = Msh::Scanner
Lexer = Msh::Lexer

class TokenStream
  attr_accessor :pos

  def initialize lexer
    @lexer = lexer
    @tokens = []
    @pos = 0
  end

  def peek
    if @pos == @tokens.size
      t = @lexer.next_token
      while %i[SPACE COMMENT].include?(t.type)
        t = @lexer.next_token
      end
      @tokens << t.dup
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

  def to_s
    "s(:#{type}, #{children.join(', ')})"
  end
end

class Parser
  attr_reader :token_stream

  def initialize token_stream
    @token_stream = token_stream
  end

  def pos
    @token_stream.pos
  end
  def pos= index
    @token_stream.pos = index
  end

  def expect *types
    token = @token_stream.peek
    return @token_stream.next if types.include?(token.type)

    nil
  end

  def s type, *children
    Node.new type, children
  end
end

# expr:       and_or | pipeline
# and_or:     pipeline AND pipeline | pipeline OR pipeline
# pipeline:   command PIPE pipeline | command
# command:    cmd_part command | cmd_part
# cmd_part:   redirect | word | assignment
# assignment: word EQ word
# word:       word_type word | word_type
# word_type:  LIT | INTERP | SUB | VAR
# redirect:   REDIRECT_OUT | REDIRECT_IN
#
class ToyParser < Parser
  def parse
    # expr
    # command
    word
  end

  def expr
    # if ao = and_or
    #   return s(:EXPR, ao)
    # els
    if p = pipeline
      return s(:EXPR, p)
    end

    nil
  end

  # def and_or
  #   loc = pos
  #   if p = pipeline
  #     if a = expect(:AND, :OR)
  #       if p2 = pipeline
  #         return s(a.type, p, p2)
  #       else
  #         pos = loc
  #       end
  #     else
  #       pos = loc
  #     end
  #   else
  #     pos = loc
  #   end
  #   nil
  # end

  def pipeline
    loc = pos
    if c = command
      loc = pos
      if expect(:PIPE)
        loc = pos
        if p = pipeline
          return s(:PIPELINE, c, *p.children)
        else
          pos = loc
        end
      else
        pos = loc
        return s(:PIPELINE, c)
      end
    end
    nil
  end

  def command
    loc = pos
    if prefix = cmd_part
      loc = pos
      if c = command
        return s(:COMMAND, prefix, c)
      else
        pos = loc
        return s(:COMMAND, prefix)
      end
    else
      loc = pos
    end
    nil
  end

  def cmd_part
    if w = word
      return s(:WORD, w)
    end
    nil
  end

  def word
    loc = pos

    if wt = word_type
      loc = pos
      if w = word
        type = wt.type == :WORD ? :LIT : wt.type
        return s(:WORD, s(type, wt.value), *w.children)
      else
        type = wt.type == :WORD ? :LIT : wt.type
        return s(:WORD, s(type, wt.value))
      end
    else
      pos = loc
    end
    nil
  end

  def word_type
    expect(:WORD, :INTERP, :SUB, :VAR)
  end
end

class Rule
  def initialize name, alts
    @name = name
    @alts = alts
  end
end
# end

module Msh
  class ParserGenerator
    def initialize code; end
  end
end

if $PROGRAM_NAME == __FILE__
  lexer = Lexer.new(ARGV.join(' '))
  # puts lexer.tokens
  # ts = TokenStream.new(lexer)

  parser = ToyParser.new(TokenStream.new(lexer))

  ast = parser.parse

  if ast
    puts ast
  else
    p ast
  end
end
# Parser.new ARGV
# Msh::ParserGenerator.new.generate(<<~EBNF)
#   expr: term '+' term | term
#   term: NAME | NUMBER

#   statement: assignment | expr | if_statement
#   expr: expr '+' term | expr '-' term | term
#   term: term '*' atom | term '/' atom | atom
#   atom: NAME | NUMBER | '(' expr ')'
#   assignment: target '=' expr
#   target: NAME
#   if_statement: 'if' expr ':' statement
# EBNF
