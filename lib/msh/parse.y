# vim: set ft=ruby:

# msh's racc parser.
#
# It creates an AST of `AST::Node` types, which are processed by the
# interpreter.
#
class Msh::Parser

rule
  code
   : expr         { result = s(:EXPR, val[0]) }
  #  | list         { result = s(:EXPR, val[0]) }
  #  | simple_list  { result = s(:EXPR, val[0]) }
  #  | and_or       { result = s(:EXPR, val[0]) }
  #  | pipeline_cmd { result = s(:EXPR, val[0]) }
   | pipeline_cmd sep { result = s(:EXPR, val[0]) }
   | command      sep { result = s(:EXPR, val[0]) }

  # separator
  sep
    : # epsilon
    | newlines

  newlines
    : NEWLINE
    | newlines NEWLINE

  #list_expr
  #  : list
  #  | list_expr expr { result = s(:LIST, *val[0].children, *val[1]) }

  ## lists.
  ##
  ## source: https://www.gnu.org/software/bash/manual/html_node/Lists.html#Lists
  ##
  ## ```
  ## A list is a sequence of one or more pipelines separated by one of the
  ## operators ‘;’, ‘&’, ‘&&’, or ‘||’, and optionally terminated by one of ‘;’,
  ## ‘&’, or a newline.  Of these list operators, ‘&&’ and ‘||’ have equal
  ## precedence, followed by ‘;’ and ‘&’, which have equal precedence.
  ##
  ## A sequence of one or more newlines may appear in a list to delimit
  ## commands, equivalent to a semicolon.
  ##
  ## If a command is terminated by the control operator ‘&’, the shell executes
  ## the command asynchronously in a subshell. This is known as executing the
  ## command in the background, and these are referred to as asynchronous
  ## commands. The shell does not wait for the command to finish, and the return
  ## status is 0 (true).  When job control is not active (see Job Control), the
  ## standard input for asynchronous commands, in the absence of any explicit
  ## redirections, is redirected from /dev/null.
  ##
  ## Commands separated by a ‘;’ are executed sequentially; the shell waits for
  ## each command to terminate in turn. The return status is the exit status of
  ## the last command executed.
  ##
  ## AND and OR lists are sequences of one or more pipelines separated by the
  ## control operators ‘&&’ and ‘||’, respectively. AND and OR lists are
  ## executed with left associativity.
  ## ```
  #list
  #  # combine adjacent lists into a single :LIST
  #  : list SEMI list {
  #                     left  = val[0].type == :LIST ? val[0].children : [val[0]]
  #                     right = val[2].type == :LIST ? val[2].children : [val[2]]
  #                     result = s(:LIST, *left, *right)
  #                   }
  #  | list SEMI
  #  | subshell
  #  | group
  #  | simple_list

  #subshell
  #  : LEFT_PAREN expr RIGHT_PAREN {
  #                                  result = val[1].type == :SUBSHELL \
  #                                    ? val[1]
  #                                    : s(:SUBSHELL,  val[1])
  #                                }
  #group
  #  : LEFT_BRACE expr RIGHT_BRACE {
  #                                  result = val[1].type == :GROUP \
  #                                    ? val[1]
  #                                    : s(:GROUP,  val[1])
  #                                }
  #simple_list
  #  : and_or
  #  | pipeline_cmd
  #  | command

  #and_or
  #  : pipeline_cmd OR  and_or       { result = s(:OR,  val[0], val[2]) }
  #  | pipeline_cmd AND and_or       { result = s(:AND, val[0], val[2]) }
  #  | pipeline_cmd OR  pipeline_cmd { result = s(:OR,  val[0], val[2]) }
  #  | pipeline_cmd AND pipeline_cmd { result = s(:AND, val[0], val[2]) }

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

  command
    : command redirections { result = s(:COMMAND, *val[0].children, val[1]) }
    | command WORD        {
                            result = s(:COMMAND,
                                       *(val.first.children + [s(:WORD, val.last)]))
                          }
    | WORD                 { result = s(:COMMAND, s(:WORD, val[0])) }

  redirections
    : redirections redirection { result = s(:REDIRECTIONS, *val[0].children, val[1]) }
    | redirection              { result = s(:REDIRECTIONS, val[0]) }

  # https://www.gnu.org/software/bash/manual/html_node/Redirections.html#Redirections
  redirection
    : DIGIT D_REDIRECT_RIGHT io_word      { result = s(:N_D_REDIRECT_OUT, val[0], val[2]) }
    |       D_REDIRECT_RIGHT io_word      { result = s(:D_REDIRECT_OUT, val[1]) }
    | DIGIT   REDIRECT_RIGHT io_word      { result = s(:N_REDIRECT_OUT, val[0], val[2]) }
    | DIGIT   REDIRECT_RIGHT PIPE io_word { result = s(:N_REDIRECT_OUT_CLOBBER, val[0], val[3]) }
    |         REDIRECT_RIGHT PIPE io_word { result = s(:REDIRECT_OUT_CLOBBER, val[2]) }
    | DIGIT   REDIRECT_LEFT  io_word      { result = s(:N_REDIRECT_IN, val[0], val[2]) }
    |         REDIRECT_RIGHT io_word      { result = s(:REDIRECT_OUT, val[1]) }
    |         REDIRECT_LEFT  io_word      { result = s(:REDIRECT_IN, val[1]) }
    # the `DUP_*` ones can only be `[\d]+` or `-`
    | DIGIT   DUP_IN         io_word      { result = s(:N_DUP_IN, val[0], val[2]) }
    | DIGIT   DUP_OUT        io_word      { result = s(:N_DUP_OUT, val[0], val[2]) }
    |         DUP_IN         io_word      { result = s(:DUP_IN, val[1]) }
    |         DUP_OUT        io_word      { result = s(:DUP_OUT, val[1]) }
    | AND     REDIRECT_RIGHT io_word      { result = s(:AND_REDIRECT_OUT, val[2]) }
    | AND   D_REDIRECT_RIGHT io_word      { result = s(:AND_D_REDIRECT_OUT, val[2]) }
    | DIGIT DIAMOND          io_word      { result = s(:DIAMOND, val[0], val[2]) }

  io_word
    : WORD
    | DIGIT
end

---- header

require 'ast'
require "msh/lexer"

---- inner

  include AST::Sexp

  attr_reader :lexer

  def initialize
    @lexer = Msh::Lexer.new
  end

  def parse(code)
    @lexer.scan_setup code
    do_parse
  rescue Racc::ParseError => e
    # TODO: better error message
    raise e.class.new "[#{line}][#{column}]: #{e.message.gsub "\n", ''}"
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
        redirections = s(:REDIRECTIONS, *(redirections + [s(:N_DUP_OUT, 2, 1)]))
        left = s(left.type, *(left.children[0...-1] + [redirections]))
      else
        left = s(left.type, *(left.children + [s(:REDIRECTIONS, s(:N_DUP_OUT, 2, 1))]))
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

class Msh::Parser
  def self.interactive
    while line = Reline.readline("parser> ", true)&.chomp
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

  # Run the parser on a file
  def self.parse_file filename
    parser = Msh::Parser.new
    p parser.parse(File.read(filename))
  rescue ParseError
    abort $ERROR_INFO
  end

  # Parse each file passed as input (if any), or run interactively
  def self.start
    if ARGV.size.positive?
      ARGV.each do |file|
        abort "#{file} is not a file!" unless File.file?(file)
        parser = Msh::Parser.new
        p parser.parse(File.read(file))
      end
    else
      Msh::Parser.interactive
    end
  end
end
