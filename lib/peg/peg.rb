# frozen_string_literal: true

# Simple PEG generator

require "lex/lex"

# peg/token_stream.rb
module Peg
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
end

# peg/parser.rb
module Peg
  class Parser
    attr_reader :token_stream

    def initialize lexer
      @lexer = lexer
      @token_stream = TokenStream.new lexer
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

    def consume_star *types
      ret = []
      ret << @token_stream.next while types.include? @token_stream.peek.type
      ret
    end

    def skip *types
      @token_stream.next while types.include? @token_stream.peek.type
    end
  end
end

# peg/grammar.rb
# peg/grammar/lexer.rb
# peg/grammar/ast.rb
# peg/grammar/parser.rb
# peg/grammar/generator.rb
module Peg
  module Grammar
    class Lexer < Lex::Lexer
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
        when "\""
          while c = advance
            if c == "\""
              @token.type = :LIT
              break
            end

            error "unexpected end of input when matching a LIT token" if c == "\0"
          end
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
        when "*"
          @token.type = :STAR
        when "+"
          @token.type = :PLUS
        when "#"
          until (c = advance) == "\n"
          end
          @token.type = :COMMENT
        else
          error "unknown #{current_token}"
        end

        return next_token if @token.type.nil? || @token.type == :SPACE

        @tokens << @token.dup.freeze
        @token
      end
    end

    module AST
      Alt = Struct.new :items, :action do
        def to_s
          i = items.map do |i|
            if Object.const_defined?("AST::Token") && i.is_a?(AST::Token)
              i.value.inspect
            else
              i
            end
          end

          if action
            "#{i.join(' ')} #{action}"
          else
            i.join(" ")
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

      Item = Struct.new :value, :zero_or_more, :one_or_more, :literal do
        def literal?
          !!literal
        end

        def to_s
          if zero_or_more
            "#{value}*"
          elsif one_or_more
            "#{value}+"
          else
            value.to_s
          end
        end
      end
    end

    # grammar: rule+ EOF
    # rule: NAME ':' alternative NEWLINE* ('|' alternative NEWLINE*)* SEMI
    # alternative: NEWLINE* alt NEWLINE* action?
    # alt: item+
    # item: NAME
    # action: '{' .* '}'
    class Parser < Peg::Parser
      def initialize string
        super(Lexer.new(string))
      end

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
              return AST::Rule.new(n.value, alts) if consume(:SEMI)
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
            return AST::Alt.new(%w[_])
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
            return AST::Alt.new(a, act.value[1...-1])
          else
            return AST::Alt.new(a, "val[0]")
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
          return AST::Item.new(name.value, true) if consume(:STAR)

          return AST::Item.new(name.value)
        elsif lit = consume(:LIT)
          return AST::Item.new(lit.value[1...-1], true) if consume(:STAR)

          i = AST::Item.new(lit.value[1...-1])
          i.literal = true
          return i
        end

        nil
      end
    end

    class Generator
      def initialize rules
        @rules = rules
        raise "no rules" if rules.nil?

        @vars = 0.step
      end

      def new_var
        "_#{@vars.next}"
      end

      def generate io = $stdout
        io.puts "# frozen_string_literal: true"
        io.puts
        io.puts "# **note**: auto-generated, do not edit."
        io.puts "#"
        io.puts "#    $ bundle exec ruby parser.rb"
        io.puts "#"
        io.puts
        io.puts 'require "reline"'
        io.puts
        io.puts '#require "lex/lex"'
        io.puts 'require "msh/lexer"'
        io.puts 'require "ast/ast"'
        io.puts 'require "peg/peg"'
        io.puts
        io.puts "class Msh::Parser < Peg::Parser"
        io.puts "  include AST::Sexp"
        io.puts
        io.puts "  def parse"
        io.puts "    #{@rules.first.name}"
        io.puts "  end"
        @rules.each do |rule|
          io.puts
          # TODO: add rule as comment
          # io.puts "  # #{rule.name}"
          # io.puts "  #   : #{rule.alts.join("\n  #   | ")}"
          io.puts "  def #{rule.name}"
          io.puts "    loc = pos"
          io.puts "    val = []"

          rule.alts.each do |alt|
            ends = []

            # We start matching by making an if statement, branching for each
            # alternative.
            #
            depth = 2
            io.puts

            # TODO: add alternate as comment
            # io.puts "    # #{alt}"

            alt.items.each_with_index do |item, _index|
              is_epsilon = item.value == "_"
              is_token = item.value == item.value.upcase
              indent = " " * (depth += 2)

              if is_epsilon
                io.puts "#{indent}if true"
                io.puts "#{indent}  val << nil"
              elsif is_token
                var = new_var

                if item.zero_or_more
                  io.puts "#{indent}if #{var} = consume_star(:#{item.value})"
                else
                  io.puts "#{indent}if #{var} = consume(:#{item.value})"
                end

                io.puts "#{indent}  val << #{var}"
              else
                var = new_var
                io.puts "#{indent}if #{var} = #{item.value}"
                io.puts "#{indent}  val << #{var}"
              end
              ends << indent
            end

            indent = " " * depth
            io.puts "#{indent}  return begin"
            io.puts "#{indent}           #{alt.action}"
            io.puts "#{indent}         end"

            ends.reverse_each do |e|
              io.puts "#{e}else"
              io.puts "#{e}  val.pop"
              io.puts "#{e}  reset loc"
              io.puts "#{e}end"
            end
          end

          io.puts "    nil"
          io.puts "  end"
        end
        io.puts "end"
        io.puts
        io.puts "if $0 == __FILE__"
        io.puts "  while line = Reline.readline('peg> ', true)"
        io.puts "    lexer = Msh::Lexer.new line"
        io.puts "    parser = Msh::Parser.new(lexer)"
        io.puts "    ast = parser.parse"
        io.puts "    puts ast"
        io.puts "  end"
        io.puts "end"
      end
    end
  end
end
