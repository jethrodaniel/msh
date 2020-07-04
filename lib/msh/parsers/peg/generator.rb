# frozen_string_literal: true

require "msh/core_extensions"
require "msh/scanner"
require "msh/lexer"
require "msh/parsers/peg"
require "msh/parsers/peg/msh"

Alt = Struct.new :items, :action do
  def to_s
    if action
      "#{items.join(' ')} #{action}"
    else
      items.join(" ")
    end
  end
end

Rule = Struct.new :name, :alts, :action do
  def to_s
    "#{name}\n" \
    "  : #{alts.join("\n  | ")}\n" \
    "  ;"
  end
end

# grammar: rule+ EOF
# rule: NAME ':' alternative NEWLINE* ('|' alternative NEWLINE*)* SEMI
# alternative: NEWLINE* alt NEWLINE* action?
# alt: item+
# item: NAME
# action: '{' .* '}'
class GrammarParser < Msh::Parsers::Peg::Base
  def parse
    skip(:NEWLINE)
    grammar
  end

  def grammar
    loc = pos
    if r = rule
      rules = [r]
      skip(:NEWLINE)
      while r = rule
        skip(:NEWLINE)
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
      skip(:NEWLINE)
      if consume(:COLON)

        skip(:NEWLINE)
        if a = alternative
          alts = [a]
          aloc = pos

          skip(:NEWLINE)
          while alt = pipe_alternative
            alts << alt
            aloc = pos
            skip(:NEWLINE)
          end
          return Rule.new(n.value, alts) if consume(:SEMI)
        end
      end
    else
      reset loc
    end
    nil
  end

  def pipe_alternative
    loc = pos
    if consume(:PIPE)
      skip(:NEWLINE)
      if alt = alternative
        return alt
      else
        return Alt.new(%w(_))
      end
    end
    nil
  end

  def alternative
    loc = pos
    skip(:NEWLINE)
    if a = alt
      skip(:NEWLINE)
      if act = consume(:ACTION)
        return Alt.new(a, act.value)
      else
        return Alt.new(a)
      end
    else
      reset loc
    end
    nil
  end

  def alt
    items = []
    while i = item
      skip(:NEWLINE)
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

    case c = advance
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
    when "{"
      @token.type = :LEFT_BRACE
      line = @scanner.line
      col = @scanner.column - 1
      l_brace_stack = [c]

      while c = advance # loop until closing `}`
        case c
        when "{"
          l_brace_stack << c
        when "}"
          break if l_brace_stack.empty?

          l_brace_stack.pop
        end
        break if l_brace_stack.empty? || @scanner.eof?
      end

      if l_brace_stack.size.positive? # || c.nil? || eof?
        error "unterminated action, expected `}` to complete `{` at line #{line}, column #{col}"
      end

      @token.type = :ACTION
      @token.column = col
      @token.line = line
    when ";"
      @token.type = :SEMI
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
      io.puts "# frozen_string_literal: true"
      io.puts ""
      io.puts 'require "msh/scanner"'
      io.puts 'require "msh/lexer"'
      io.puts 'require "msh/parsers/peg"'
      io.puts 'require "msh/parsers/peg/generator"'
      io.puts ""
      io.puts "# auto-generated, do not edit."
      io.puts "#"
      io.puts "#    $ bundle exec ruby parser.rb"
      io.puts "#"
      io.puts "class MshParser < Msh::Parsers::Peg::Base"
      io.puts "  def parse"
      io.puts "    program"
      io.puts "  end"
      @rules.each do |rule|
        io.puts
        io.puts "  # #{rule.name}"
        io.puts "  #   : #{rule.alts.join("\n  #   | ")}"
        io.puts "  def #{rule.name}"
        io.puts "    loc = pos"

        # A bit messy here to deal with right-recursive rules. Given this rule,
        #
        #    program: expr SEMI program
        #
        # we want to output
        #
        #    s(:PROGRAM, e, *p.children)
        #
        # instead of
        #
        #    s(:PROGRAM, e, p)
        #
        # to avoid unneccesary nesting of nodes.
        #
        rule.alts.each do |alt|
          items = []

          # We start matching by making an if statement, branching for each
          # alternative.
          #
          #     # WORD expr SEMI
          #     if (true \
          #       && _word = consume(:WORD) \
          #         && _expr = expr \
          #           && _semi = consume(:SEMI)
          #     ) then
          #       ...
          #     else
          #       reset loc
          #     end
          #
          indent = 6
          io.puts "    # #{alt}"
          io.puts "    if (true \\"

          alt.items.each_with_index do |item, index|
            is_epsilon = item == "_"
            var = "_#{item.downcase}"
            indent = ' ' * ((2 * index) + 8)

            if is_epsilon
              io.print "      # epsilon"
            elsif item == item.upcase # TOKEN
              var = "#{var}#{items.size}" if items.include? var
              items << var

              io.print "#{indent}&& #{var} = consume(:#{item.to_sym})"
            else # rule
              var = "#{var}#{items.size}" if items.include? var
              items << var

              io.print "#{indent}&& #{var} = #{item}"
            end

            # line continuation
            io.print " \\" unless index == alt.size || is_epsilon
            io.puts
          end
          io.puts "    ) then"

          items.map! do |i|
            case i
            when i.upcase
              "#{i}.value"
            when "_#{rule.name}"
              "*#{i}.children"
            else
              i
            end
          end

          # io.puts "      return (#{alt.action[1...-1]})"
          io.puts "      return begin"
          io.puts "               val = [#{items.join(', ')}]"
          if alt.action
            io.puts "               #{alt.action[1...-1]}"
          else
            io.puts "               val[0]"
          end
          io.puts "             end"
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
    program
      : expr SEMI program { s(:PROG, val[0], *val[2].children) }
      | expr SEMI         { s(:PROG, val[0]) }
      | expr              { s(:PROG, val[0]) }
      | _                 { s(:NOOP) }
      ;
    expr
      : and_or    { s(:EXPR, val[0]) }
      | pipeline  { s(:EXPR, val[0]) }
      ;
    and_or
      : pipeline AND pipeline { s(:AND, *val) }
      | pipeline OR pipeline  { s(:OR, *val) }
      ;
    pipeline
      : command PIPE pipeline { s(:PIPELINE, val[0], *val[1].children) }
      | command
      ;
    command
      : cmd_part command { s(:COMMAND, val[0], *val[1].children) }
      | cmd_part         { s(:COMMAND, val[0]) }
      ;
    cmd_part
      : redirect | word | assignment
      ;
    assignment
      : word EQ word { s(:ASSIGN, val[0], val[2]) }
      ;
    word
      : word_type word { s(:WORD, val[0], *val[1].children) }
      | word_type      { s(:WORD, s(val[0].type, val[0].value)) }
      ;
    word_type: LIT | INTERP | SUB | VAR;
    redirect:  REDIRECT_OUT | REDIRECT_IN;
  GR

  rules = parser.parse
  puts rules

  gen = Msh::ParserGenerator.new rules
  puts "-> parser.rb"
  File.open("parser.rb", "w") { |f| gen.generate f }
end
