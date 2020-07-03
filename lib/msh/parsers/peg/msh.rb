# frozen_string_literal: true

require "msh/parsers/peg"

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
module Msh
  module Parsers
    module Peg
      class Msh < Base
        DESC = "PEG parser"

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
            when :REDIRECT_IN
              n ||= 0
            end

            if f = word
              return s(:REDIRECT, s(r.type, n, f))
            end
          else
            reset loc
          end
          nil
        end

        # Run the parser interactively, i.e, run a loop and parse user input.
        def self.interactive
          puts DESC
          Parsers.input_loop do |line|
            lexer = ::Msh::Lexer.new line
            parser = new(TokenStream.new(lexer))
            puts parser.parse
          rescue Errors::ParseError => e
            puts e.message
          end
        end

        def self.start *args
          Parsers.start self, *args
        end
      end
    end
  end
end
