# frozen_string_literal: true

require "msh/core_extensions"
require "msh/scanner"
require "msh/lexer"

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
      "#{' ' * indent}s(:#{type}, #{children.first})"
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

class Parser
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

# program:    expr | expr SEMI | expr SEMI program
# expr:       and_or | pipeline
# and_or:     pipeline AND pipeline | pipeline OR pipeline
# pipeline:   command PIPE pipeline | command
# command:    cmd_part command | cmd_part
# cmd_part:   redirect | word | assignment
# assignment: word EQ word
# word:       word_type word | word_type
# word_type:  WORD | INTERP | SUB | VAR
# redirect:   REDIRECT_OUT | REDIRECT_IN
#
class ToyParser < Parser
  def parse
    program
  end

  def program
    loc = pos
    if e = expr
      if s = consume(:SEMI)
        if p = program
          return s(:PROG, e, *p.children)
        else
          reset loc
        end

        return s(:PROG, e)
      end
      return s(:PROG, e)
    else
      reset loc
    end
    return s(:NOOP) if consume :EOF

    nil
  end

  def expr
    if ao = and_or
      return s(:EXPR, ao)
    elsif p = pipeline
      return s(:EXPR, p)
    end

    nil
  end

  def and_or
    loc = pos
    if p = pipeline
      if a = consume(:AND, :OR)
        if p2 = pipeline
          return s(a.type, p, p2)
        else
          reset loc
        end
      else
        reset loc
      end
    else
      reset loc
    end
    nil
  end

  def pipeline
    loc = pos
    if c = command
      loc = pos
      if consume(:PIPE)
        if p = pipeline
          if p.type == :PIPELINE
            return s(:PIPELINE, c, *p.children)
          else
            return s(:PIPELINE, c, p)
          end
        else
          reset loc
        end
      else
        reset loc
        return c
      end
    else
      reset loc
    end
    nil
  end

  def command
    loc = pos
    if prefix = cmd_part
      loc = pos
      if c = command
        return s(:COMMAND, prefix, *c.children)
      else
        reset loc
        return s(:COMMAND, prefix)
      end
    else
      loc = pos
    end
    nil
  end

  def cmd_part
    loc = pos
    if w = word
      return w
    elsif r = redirect
      return r
    else
      reset loc
    end

    nil
  end

  def word
    loc = pos

    if wt = word_type
      loc = pos
      if token_stream.in_word? && w = word
        type = wt.type == :WORD ? :LIT : wt.type
        return s(:WORD, s(type, wt.value), *w.children)
      else
        reset loc
        type = wt.type == :WORD ? :LIT : wt.type
        return s(:WORD, s(type, wt.value))
      end
    else
      reset loc
    end
    nil
  end

  def word_type
    consume(:LIT, :INTERP, :SUB, :VAR)
  end

  def redirect
    loc = pos
    if r = consume(:REDIRECT_OUT, :REDIRECT_IN, :APPEND_OUT)
      digits, _redir = r.value.chars.partition { |c| c.match? /\d/ }
      n = digits.join
      n = n == "" ? nil : n.to_i

      case r.type
      when :REDIRECT_OUT, :APPEND_OUT
        n ||= 1
      else :REDIRECT_IN
        n ||= 0
      end

      if f = word
        return s(:REDIRECT, s(r.type, n, f))
      else
        reset loc
      end
    else
      reset loc
    end
    nil
  end
end

class Rule
  attr_reader :name, :alts

  def initialize name, alts
    @name = name
    @alts = alts
  end

  def to_s
    alts = @alts.map { |a| a.join(' ') }
    "#{@name}: #{alts.join(' | ')}"
  end
end

# grammar: rule+ EOF
# rule: NAME ':' alternative ('|' alternative)* NEWLINE
# alternative: item+
# item: NAME
class GrammarParser < Parser
  def parse
    grammar
  end

  def grammar
    loc = pos
    if r = rule
      rules = [r]
      while r = rule
        rules << r
      end
      return rules if consume(:EOF)
    else
      reset loc
    end
    nil
  end

  def rule
    loc = pos
    if n = consume(:NAME)
      if consume(:COLON)

        if a = alternative
          alts = [a]
          aloc = pos
          while consume(:PIPE) && alt = alternative
            alts << alt
            aloc = pos
          end
          # reset aloc
          return Rule.new(n.value, alts) if consume(:NEWLINE)
          # return Rule.new(n.value, alts.map(&:first)) if consume(:NEWLINE)
        end
      end
    else
      reset loc
    end
    nil
  end

  def alternative
    items = []
    while i = item
      items << i
    end
    items
  end

  def item
    if name = consume(:NAME)
      return name.value
    end

    nil
  end
end

class GrammarLexer < Msh::BaseLexer
  def next_token
    reset_and_set_start
  end

  def next_token
    reset_and_set_start

    letter = -> c { ("a".."z").cover?(c) || ("A".."Z").cover?(c) || c == "_" }

    # case c = advance
    case t = advance
    when "\0"
      error "out of input" if @tokens.last&.type == :EOF
      @token.type = :EOF

    when letter
      while letter.(@scanner.current_char)
        advance
      end
      @token.type = :NAME
    when " ", "\t"
      consume_whitespace
    when ":"
      @token.type = :COLON
    when "|"
      @token.type = :PIPE
    when "\n"
      @token.type = :NEWLINE
    else
      error "unknown #{current_token}"
    end

    return next_token if @token.type.nil? || @token.type == :SPACE

    @tokens << @token.dup.freeze
    @token
  end
end

module Msh
  class ParserGenerator
    def initialize rules
      @rules = rules
    end

    def generate io = $stdout
      io.puts "class ToyParser < Parser"
      io.puts "  def parse"
      io.puts "    program"
      io.puts "  end"
      @rules.each do |rule|
        io.puts
        io.puts "  def #{rule.name}"
        io.puts "    loc = pos"

        rule.alts.each do |alt|
          rule_items = []
          token_items = []

          indent = 6
          io.puts "    if (true \\"
          alt.each_with_index do |item, index|
            var = "_#{item.downcase}"
            if item == item.upcase # TOKEN
              if token_items.include? var
                var = "#{var}#{token_items.size}"
              end
              token_items << var

              io.print "#{' ' * (indent + 2*index)}&& #{var} = consume(:#{item.to_sym})"
              io.print " \\" unless index == alt.size - 1
              io.puts
            else
              if rule_items.include? var
                var = "#{var}#{rule_items.size}"
              end
              rule_items << var

              io.print "#{' ' * (indent + 2*index)}&& #{var} = #{item}"
              io.print " \\" unless index == alt.size - 1
              io.puts
            end
          end
          io.puts "    ) then"

          if rule_items.empty?
            rest = token_items.map { |t| "#{t}.value" }.join ", "
            node_type = alt.first
          else
            rest = rule_items.map { |i| i == "_#{rule.name}" ? "*#{i}.children" : i }.join(', ')
            node_type = rule.name.upcase
          end
          io.puts "      return s(:#{node_type}, #{rest})"
          io.puts "    else"
          io.puts "      reset loc"
          io.puts "    end"
          io.puts
        end

        io.puts "    nil"
        io.puts "  end"
      end
      io.puts "end"
    end
  end
end

if $PROGRAM_NAME == __FILE__
  parser = GrammarParser.new(TokenStream.new(GrammarLexer.new(<<~GR)))
    program:    expr   | expr SEMI | expr SEMI program
    expr:       and_or | pipeline
    and_or:     pipeline AND pipeline | pipeline OR pipeline
    pipeline:   command PIPE pipeline | command
    command:    cmd_part command | cmd_part
    cmd_part:   redirect | word | assignment
    assignment: word EQ word
    word:       word_type word | word_type
    word_type:  LIT | INTERP | SUB | VAR
    redirect:   REDIRECT_OUT | REDIRECT_IN
  GR

  rules = parser.parse
  puts rules.map(&:to_s)

  gen = Msh::ParserGenerator.new rules

  puts gen.generate

  # print "peg> "
  # while line = gets.chomp
  while line = Reline.readline("peg> ", true)
    lexer = Msh::Lexer.new line
    parser = ToyParser.new(TokenStream.new(lexer))
    ast = parser.parse

    if ast
      puts ast
    else
      p ast
    end

    if line == "q"
      puts "bye!"
      exit
    end

    # print "peg> "
  end
end
