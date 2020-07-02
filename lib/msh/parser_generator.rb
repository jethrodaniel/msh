# frozen_string_literal: true

require "msh/core_extensions"
require "msh/scanner"
require "msh/lexer"
require "msh/parsers/peg"
require "msh/parsers/peg/msh"

class Rule
  attr_reader :name, :alts

  def initialize name, alts
    @name = name
    @alts = alts
  end

  def to_s
    alts = @alts.map { |a| a.join(" ") }
    "#{@name}: #{alts.join(' | ')}"
  end
end

# grammar: rule+ EOF
# rule: NAME ':' alternative ('|' alternative)* NEWLINE
# alternative: item+
# item: NAME
class GrammarParser < Msh::Parsers::Peg::Base
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
      advance while letter.call(@scanner.current_char)
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
      io.puts 'require "msh/scanner"'
      io.puts 'require "msh/lexer"'
      io.puts 'require "msh/parsers/peg"'
      io.puts ""
      io.puts "# auto-generated, do not edit."
      io.puts "#"
      io.puts "#    $ ruby parser.rb"
      io.puts "#"
      io.puts "class MshParser < Msh::Parsers::Peg"
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
              var = "#{var}#{token_items.size}" if token_items.include? var
              token_items << var

              io.print "#{' ' * (indent + 2 * index)}&& #{var} = consume(:#{item.to_sym})"
              io.print " \\" unless index == alt.size - 1
              io.puts
            else
              var = "#{var}#{rule_items.size}" if rule_items.include? var
              rule_items << var

              io.print "#{' ' * (indent + 2 * index)}&& #{var} = #{item}"
              io.print " \\" unless index == alt.size - 1
              io.puts
            end
          end
          io.puts "    ) then"

          if rule_items.empty?
            rest = token_items.map { |t| "#{t}.value" }.join ", "
            node_type = alt.first
          else
            rest = rule_items.map { |i| i == "_#{rule.name}" ? "*#{i}.children" : i }.join(", ")
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
      io.puts
      io.puts "if $0 == __FILE__"
      io.puts "  while line = Reline.readline('peg> ', true)"
      io.puts "    lexer = Msh::Lexer.new line"
      io.puts "    parser = MshParser.new(TokenStream.new(lexer))"
      io.puts "    ast = parser.parse"
      io.puts "    puts ast"
      io.puts "  end"
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
  puts "-> parser.rb"
  File.open("parser.rb", "w") { |f| gen.generate f }
end
