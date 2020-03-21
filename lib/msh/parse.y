# vim: set ft=ruby:

# msh's racc parser.
#
# It creates an AST of `AST::Node` types, which are processed by the
# interpreter.
#
class Msh::Parser

rule
  code
   : expr             { result = s(:EXPR, val[0]) }
   | and_or           { result = s(:EXPR, val[0]) }
   | list             { result = s(:EXPR, val[0]) }
   | simple_list      { result = s(:EXPR, val[0]) }
   | pipeline_cmd     { result = s(:EXPR, val[0]) }
   | pipeline_cmd sep { result = s(:EXPR, val[0]) }
   | command      sep { result = s(:EXPR, val[0]) }
   |              sep { result = s(:NOOP) } # nothing as input

  sep
    : /* epsilon */
    | newlines

  newlines
    : NEWLINE
    | newlines NEWLINE

  #list_expr
  #  : list
  #  | list_expr expr { result = s(:LIST, *val[0].children, *val[1]) }

  # source: https://www.gnu.org/software/bash/manual/html_node/Lists.html#Lists
  list
    # combine adjacent lists into a single :LIST
    : list SEMI list {
                       left  = val[0].type == :LIST ? val[0].children : [val[0]]
                       right = val[2].type == :LIST ? val[2].children : [val[2]]
                       result = s(:LIST, *left, *right)
                     }
    | list SEMI
    | simple_list

  simple_list
    : and_or
    | pipeline_cmd
    | command

  and_or
    : pipeline_cmd OR      and_or       { result = s(:OR,  val[0], val[2]) }
    | pipeline_cmd AND_AND and_or       { result = s(:AND, val[0], val[2]) }
    | pipeline_cmd OR      pipeline_cmd { result = s(:OR,  val[0], val[2]) }
    | pipeline_cmd AND_AND pipeline_cmd { result = s(:AND, val[0], val[2]) }

  pipeline_cmd
    :          BANG pipeline { result = s(:NEG_PIPELINE, *val[1].children) }
    | time_cmd BANG pipeline { result = s(:NEG_PIPELINE, *([val[0]] + val[2].children)) }
    | time_cmd      pipeline { result = s(:PIPELINE, *([val[0]] + val[1].children)) }
    | pipeline

  time_cmd
    : TIME          { result = s(:TIME) }
    | TIME TIME_OPT { result = s(:TIME_P) }

  pipeline
    # : pipeline PIPE_AND pipeline { result = s(:PIPELINE_AND, *val[0].children, *val[2].children) }
    # | pipeline PIPE_AND command  { result = s(:PIPELINE_AND, *val[0].children, val[2]) }
    # | command  PIPE_AND pipeline { result = s(:PIPELINE_AND, val[0], *val[2].children) }
    : command  PIPE_AND pipeline { result = expand_PIPE_AND :left => val[0], :right => val[2] }
    | command  PIPE_AND command  { result = expand_PIPE_AND :left => val[0], :right => val[2] }
    | pipeline PIPE pipeline     { result = s(:PIPELINE, *val[0].children, *val[2].children) }
    | pipeline PIPE command      { result = s(:PIPELINE, *val[0].children, val[2]) }
    | command  PIPE pipeline     { result = s(:PIPELINE, val[0], *val[2].children) }
    | command  PIPE command      { result = s(:PIPELINE, val[0], val[2]) }
    | command

  command:
    : simple_command
    | simple_command redirections { result = s(:COMMAND, *val[0].children, val[1]) }
    | group
    | group          redirections { result = s(:GROUP, *val[0].children, val[1]) }
    | subshell
    | subshell       redirections { result = s(:SUBSHELL, *val[0].children, val[1]) }

  group
    : LEFT_BRACE list RIGHT_BRACE {
                                    result = val[1].type == :GROUP \
                                      ? val[1]
                                      : s(:GROUP,  val[1])
                                  }

  subshell
    : LEFT_PAREN list RIGHT_PAREN {
                                    result = val[1].type == :SUBSHELL \
                                      ? val[1]
                                      : s(:SUBSHELL,  val[1])
                                  }

  simple_command
    : simple_command WORD         {
                                    result = s(:COMMAND,
                                               *(val.first.children + [s(:WORD, val.last)]))
                                  }
    | simple_command TIME         {
                                    result = s(:COMMAND,
                                               *(val.first.children + [s(:WORD, val.last)]))
                                  }
    | WORD                        { result = s(:COMMAND, s(:WORD, val[0])) }

  redirections
    : redirections redirection { result = s(:REDIRECTIONS, *val[0].children, val[1]) }
    | redirection              { result = s(:REDIRECTIONS, val[0]) }

  # https://www.gnu.org/software/bash/manual/html_node/Redirections.html#Redirections
  redirection
    # 3.6.9 Moving File Descriptors
    #
    #     [n]<&digit-
    #     [n]>&digit-
    #
    : MOVE_FD     {
                    unless match = val[0].match(/(\d+)[<>]&(\d+)\-/)
                      abort "expected `[n]<&digit-`, but got `#{val[0]}`"
                    end

                    n, digit = match.captures.map(&:to_i)
                    result = s(:MOVE_FD, n, digit)
                  }

    # 3.6.10 Opening File Descriptors for Reading and Writing
    #
    #     [n]<>word
    #
    | OPEN_RW WORD {
                     unless match = val[0].match(/(\d+)<>/)
                       abort "expected `[n]<>word`, but got `#{val[0]}`"
                     end

                     n = match.captures.first.to_i
                     result = s(:OPEN_RW, n, val[1])
                   }

    # 3.6.8 Duplicating File Descriptors
    #
    #     [n]<&word      duplicate input file descriptors
    #     [n]>&word      duplicate output file descriptors
    #
    # note: `word` must be a number or `-`
    #
    | DUP WORD     {
                     unless match = val[0].match(/(\d+)[<>]&/)
                       abort "expected `[n]<&word` or `[n]>&word`, but got `#{val[0]}`"
                     end

                     n = match.captures.first.to_i
                     word = val[1]
                     unless word == "-" || word.match?(/\d+/)
                       abort "[n][<>]&word, expected `-` or a digit"
                     end

                     word = word.to_i if word.match?(/\d+/)

                     result = s(:DUP, n, word)
                   }

    # 3.6.3 Appending Redirected Output
    #
    #     [n]>>word
    #
    | APPEND WORD  {
                     unless match = val[0].match(/(\d+)[>>]/)
                       abort "expected `[n]>>word`, but got `#{val[0]}`"
                     end

                     n = match.captures.first.to_i
                     result = s(:APPEND, n, val[1])
                   }

    # 3.6.5 Appending Standard Output and Standard Error
    #
    #     &>>word
    | APPEND_BOTH WORD  {
                          result = s(:APPEND_BOTH, val[1])
                        }

    # 3.6.4 Redirecting Standard Output and Standard Error
    #
    #     &>word
    | REDIRECT_BOTH WORD  {
                            result = s(:REDIRECT_BOTH, val[1])
                          }

    # 3.6.1 Redirecting Input
    # 3.6.2 Redirecting Output
    #
    #     [n]<word
    #     [n]>[|]word
    #
    | REDIRECT WORD {
                      unless match = val[0].match(/(\d+)[<>]/)
                        abort "expected `[n]<word`, but got `#{val[0]}`"
                      end

                      n = match.captures.first.to_i
                      result = s(:REDIRECT, n, val[1])
                    }
    | REDIRECT_NOCLOBBER WORD {
                                unless match = val[0].match(/(\d+)[<>]/)
                                  abort "expected `[n]>[|]word`, but got `#{val[0]}`"
                                end

                                n = match.captures.first.to_i
                                result = s(:REDIRECT_NOCLOBBER, n, val[1])
                              }

end

---- header

require 'ast'
require "msh/lexer"

---- inner

  include ::AST::Sexp

  attr_reader :lexer

  def initialize
    @lexer = Msh::Lexer.new
  end

  def parse(code)
    @lexer.scan_setup code
    do_parse
  rescue Racc::ParseError => e
    # TODO: better error message
    raise Racc::ParseError, "[#{line}][#{column}]: #{e.message.gsub "\n", ''}"
  end

  def next_token
    @lexer.next_token
  end

  def line
    @lexer.line
  end

  def column
    @lexer.column
  end

  private

  # `a |& b` is semantic sugar for `a 2>&1 | a`.
  #
  # @param left [AST::Node]
  # @param right [AST::Node]
  def expand_PIPE_AND left:, right:
    case left.type
    when :COMMAND
      if left.children.last.type == :REDIRECTIONS
        redirections = left.children.last.children
        redirections = s(:REDIRECTIONS, *(redirections + [s(:DUP, 2, 1)]))
        left = s(left.type, *(left.children[0...-1] + [redirections]))
      else
        left = s(left.type, *(left.children + [s(:REDIRECTIONS, s(:DUP, 2, 1))]))
      end

      case right.type
      when :PIPELINE
        s(:PIPELINE, left, *right.children)
      when :COMMAND
        s(:PIPELINE, left, right)
      else
        abort "expected :COMMAND or :PIPELINE, got `#{left.type}`"
      end
    when :PIPELINE
      abort "todo"
    else
      abort "expected :COMMAND or :PIPELINE, got `#{left.type}`"
    end
  end

---- footer

module Msh
  class Parser
    def self.interactive
      while line = Readline.readline("parser> ", true)&.chomp
        case line
        when "q", "quit", "exit"
          puts "goodbye! <3"
          exit
        else
          begin
            parser = Msh::Parser.new
            p parser.parse(line)
          rescue Racc::ParseError => e
            # TODO: better error message
            puts "[#{parser.line}][#{parser.column}]: #{e.message.gsub "\n", ''}"
          end
        end
      end
    end

    # Parse each file passed as input (if any), or run interactively
    def self.start args = ARGV
      return Msh::Parser.interactive if args.size.zero?

      args.each do |file|
        abort "#{file} is not a file!" unless File.file?(file)
        parser = Msh::Parser.new
        p parser.parse(File.read(file))
      end
    end
  end
end
