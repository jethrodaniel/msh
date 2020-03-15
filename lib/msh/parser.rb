#
# DO NOT MODIFY!!!!
# This file is automatically generated by Racc 1.4.16
# from Racc grammar file "".
#

require 'racc/parser.rb'


require 'ast'
require "msh/lexer"

module Msh
  class Parser < Racc::Parser

module_eval(<<'...end parse.y/module_eval...', 'parse.y', 224)

  include AST::Sexp

  attr_reader :lexer

  def initialize
    @lexer = Msh::Lexer.new

    # Use with conjunction with racc's `--debug` option
    @yydebug = true
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

...end parse.y/module_eval...
##### State transition tables begin ###

racc_action_table = [
    38,   -35,   -35,    27,    28,    21,    27,    28,    37,    40,
    41,    42,    43,    44,    45,    46,    47,     2,    10,    32,
   -16,    22,    11,    14,    18,    22,    19,    18,    20,    19,
    -9,    20,    78,    10,   -18,   -15,    22,    11,    14,    29,
    27,    28,    18,    34,    19,    77,    20,    11,    14,    35,
    11,    14,    18,    56,    19,    18,    20,    19,    34,    20,
    11,    14,    34,    11,    14,    18,    70,    19,    18,    20,
    19,    71,    20,    40,    41,    42,    43,    44,    45,    46,
    47,    40,    41,    42,    43,    44,    45,    46,    47,    40,
    41,    42,    43,    44,    45,    46,    47,    40,    41,    42,
    43,    44,    45,    46,    47,    40,    41,    42,    43,    44,
    45,    46,    47,    18,    18,    19,    19,    20,    20,    18,
    18,    19,    19,    20,    20,    18,    72,    19,    73,    20,
    10,   -17,    24,    25,    24,    25,    24,    25,    24,    25,
    27,    28,    27,    28,    27,    28,    74,    75,    76,    22,
    34,    34,    34,    34 ]

racc_action_check = [
    15,    54,    54,    31,    31,     1,    54,    54,    15,    15,
    15,    15,    15,    15,    15,    15,    15,     0,     0,    12,
     3,    55,     0,     0,    12,     4,    12,     0,    12,     0,
     7,     0,    55,     7,     7,     5,    50,    18,    18,     9,
     7,     7,    18,    13,    18,    50,    18,    19,    19,    14,
    22,    22,    19,    21,    19,    22,    19,    22,    30,    22,
    24,    24,    33,    25,    25,    24,    41,    24,    25,    24,
    25,    42,    25,    16,    16,    16,    16,    16,    16,    16,
    16,    17,    17,    17,    17,    17,    17,    17,    17,    36,
    36,    36,    36,    36,    36,    36,    36,    48,    48,    48,
    48,    48,    48,    48,    48,    49,    49,    49,    49,    49,
    49,    49,    49,    11,    27,    11,    27,    11,    27,    28,
    32,    28,    32,    28,    32,    34,    43,    34,    44,    34,
     6,     6,     6,     6,    53,    53,    58,    58,    60,    60,
    62,    62,    64,    64,    67,    67,    45,    46,    47,    57,
    63,    65,    66,    68 ]

racc_action_pointer = [
    15,     5,   nil,    16,    21,    31,   127,    30,   nil,    36,
   nil,   101,    12,    32,    40,    -8,    56,    64,    30,    40,
   nil,    53,    43,   nil,    53,    56,   nil,   102,   107,   nil,
    47,    -7,   108,    51,   113,   nil,    72,   nil,   nil,   nil,
   nil,    50,    55,   110,   112,   130,   131,   132,    80,    88,
    32,   nil,   nil,   129,    -4,    17,   nil,   145,   131,   nil,
   133,   nil,   130,   139,   132,   140,   141,   134,   142,   nil,
   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil,   nil ]

racc_action_default = [
    -9,   -57,    -1,    -2,    -3,    -4,    -5,   -35,    -8,   -10,
   -11,   -57,   -57,   -26,   -27,   -36,   -38,   -40,   -57,   -57,
   -46,   -57,   -14,    -6,   -57,   -57,    -7,   -57,   -57,   -12,
   -23,   -35,   -57,   -25,   -57,   -28,   -37,   -44,   -45,   -48,
   -49,   -57,   -57,   -57,   -57,   -57,   -57,   -57,   -39,   -41,
   -57,   -15,   -16,   -17,   -18,   -57,    79,   -13,   -21,   -19,
   -22,   -20,   -30,   -29,   -34,   -33,   -24,   -32,   -31,   -47,
   -50,   -51,   -52,   -53,   -54,   -55,   -56,   -42,   -43 ]

racc_goto_table = [
     7,     3,     4,     8,     1,     6,    36,    48,    49,    23,
    26,     5,   nil,   nil,   nil,    30,    33,   nil,    54,    54,
    50,    55,    54,   nil,    57,    59,    61,    62,    64,    58,
    60,    63,    65,    69,    67,   nil,    66,   nil,    68,   nil,
   nil,   nil,   nil,   nil,   nil,    69,    69 ]

racc_goto_check = [
     7,     2,     3,     6,     1,     5,    12,    12,    12,     6,
     6,     4,   nil,   nil,   nil,     9,     9,   nil,     7,     7,
     3,     3,     7,   nil,     3,     2,     2,     7,     7,     5,
     5,     9,     9,    15,     7,   nil,     9,   nil,     9,   nil,
   nil,   nil,   nil,   nil,   nil,    15,    15 ]

racc_goto_pointer = [
   nil,     4,     1,     2,    11,     5,     3,     0,   nil,     4,
   nil,   nil,    -9,   nil,   nil,    -3 ]

racc_goto_default = [
   nil,   nil,    52,   nil,    51,    53,   nil,    31,     9,    13,
    12,    15,   nil,    16,    17,    39 ]

racc_reduce_table = [
  0, 0, :racc_error,
  1, 26, :_reduce_1,
  1, 26, :_reduce_2,
  1, 26, :_reduce_3,
  1, 26, :_reduce_4,
  1, 26, :_reduce_5,
  2, 26, :_reduce_6,
  2, 26, :_reduce_7,
  1, 26, :_reduce_8,
  0, 31, :_reduce_none,
  1, 31, :_reduce_none,
  1, 33, :_reduce_none,
  2, 33, :_reduce_none,
  3, 28, :_reduce_13,
  2, 28, :_reduce_none,
  1, 28, :_reduce_none,
  1, 29, :_reduce_none,
  1, 29, :_reduce_none,
  1, 29, :_reduce_none,
  3, 27, :_reduce_19,
  3, 27, :_reduce_20,
  3, 27, :_reduce_21,
  3, 27, :_reduce_22,
  2, 30, :_reduce_23,
  3, 30, :_reduce_24,
  2, 30, :_reduce_25,
  1, 30, :_reduce_none,
  1, 35, :_reduce_27,
  2, 35, :_reduce_28,
  3, 34, :_reduce_29,
  3, 34, :_reduce_30,
  3, 34, :_reduce_31,
  3, 34, :_reduce_32,
  3, 34, :_reduce_33,
  3, 34, :_reduce_34,
  1, 34, :_reduce_none,
  1, 32, :_reduce_none,
  2, 32, :_reduce_37,
  1, 32, :_reduce_none,
  2, 32, :_reduce_39,
  1, 32, :_reduce_none,
  2, 32, :_reduce_41,
  3, 38, :_reduce_42,
  3, 39, :_reduce_43,
  2, 36, :_reduce_44,
  2, 36, :_reduce_45,
  1, 36, :_reduce_46,
  2, 37, :_reduce_47,
  1, 37, :_reduce_48,
  1, 40, :_reduce_49,
  2, 40, :_reduce_50,
  2, 40, :_reduce_51,
  2, 40, :_reduce_52,
  2, 40, :_reduce_53,
  2, 40, :_reduce_54,
  2, 40, :_reduce_55,
  2, 40, :_reduce_56 ]

racc_reduce_n = 57

racc_shift_n = 79

racc_token_table = {
  false => 0,
  :error => 1,
  :expr => 2,
  :NEWLINE => 3,
  :SEMI => 4,
  :OR => 5,
  :AND_AND => 6,
  :BANG => 7,
  :TIME => 8,
  :TIME_OPT => 9,
  :PIPE_AND => 10,
  :PIPE => 11,
  :LEFT_BRACE => 12,
  :RIGHT_BRACE => 13,
  :LEFT_PAREN => 14,
  :RIGHT_PAREN => 15,
  :WORD => 16,
  :MOVE_FD => 17,
  :OPEN_RW => 18,
  :DUP => 19,
  :APPEND => 20,
  :APPEND_BOTH => 21,
  :REDIRECT_BOTH => 22,
  :REDIRECT => 23,
  :REDIRECT_NOCLOBBER => 24 }

racc_nt_base = 25

racc_use_result_var = true

Racc_arg = [
  racc_action_table,
  racc_action_check,
  racc_action_default,
  racc_action_pointer,
  racc_goto_table,
  racc_goto_check,
  racc_goto_default,
  racc_goto_pointer,
  racc_nt_base,
  racc_reduce_table,
  racc_token_table,
  racc_shift_n,
  racc_reduce_n,
  racc_use_result_var ]

Racc_token_to_s_table = [
  "$end",
  "error",
  "expr",
  "NEWLINE",
  "SEMI",
  "OR",
  "AND_AND",
  "BANG",
  "TIME",
  "TIME_OPT",
  "PIPE_AND",
  "PIPE",
  "LEFT_BRACE",
  "RIGHT_BRACE",
  "LEFT_PAREN",
  "RIGHT_PAREN",
  "WORD",
  "MOVE_FD",
  "OPEN_RW",
  "DUP",
  "APPEND",
  "APPEND_BOTH",
  "REDIRECT_BOTH",
  "REDIRECT",
  "REDIRECT_NOCLOBBER",
  "$start",
  "code",
  "and_or",
  "list",
  "simple_list",
  "pipeline_cmd",
  "sep",
  "command",
  "newlines",
  "pipeline",
  "time_cmd",
  "simple_command",
  "redirections",
  "group",
  "subshell",
  "redirection" ]

Racc_debug_parser = false

##### State transition tables end #####

# reduce 0 omitted

module_eval(<<'.,.,', 'parse.y', 11)
  def _reduce_1(val, _values, result)
     result = s(:EXPR, val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 12)
  def _reduce_2(val, _values, result)
     result = s(:EXPR, val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 13)
  def _reduce_3(val, _values, result)
     result = s(:EXPR, val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 14)
  def _reduce_4(val, _values, result)
     result = s(:EXPR, val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 15)
  def _reduce_5(val, _values, result)
     result = s(:EXPR, val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 16)
  def _reduce_6(val, _values, result)
     result = s(:EXPR, val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 17)
  def _reduce_7(val, _values, result)
     result = s(:EXPR, val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 18)
  def _reduce_8(val, _values, result)
     result = s(:NOOP)
    result
  end
.,.,

# reduce 9 omitted

# reduce 10 omitted

# reduce 11 omitted

# reduce 12 omitted

module_eval(<<'.,.,', 'parse.y', 36)
  def _reduce_13(val, _values, result)
                           left  = val[0].type == :LIST ? val[0].children : [val[0]]
                       right = val[2].type == :LIST ? val[2].children : [val[2]]
                       result = s(:LIST, *left, *right)

    result
  end
.,.,

# reduce 14 omitted

# reduce 15 omitted

# reduce 16 omitted

# reduce 17 omitted

# reduce 18 omitted

module_eval(<<'.,.,', 'parse.y', 49)
  def _reduce_19(val, _values, result)
     result = s(:OR,  val[0], val[2])
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 50)
  def _reduce_20(val, _values, result)
     result = s(:AND, val[0], val[2])
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 51)
  def _reduce_21(val, _values, result)
     result = s(:OR,  val[0], val[2])
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 52)
  def _reduce_22(val, _values, result)
     result = s(:AND, val[0], val[2])
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 55)
  def _reduce_23(val, _values, result)
     result = s(:NEG_PIPELINE, *val[1].children)
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 56)
  def _reduce_24(val, _values, result)
     result = s(:NEG_PIPELINE, *([val[0]] + val[2].children))
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 57)
  def _reduce_25(val, _values, result)
     result = s(:PIPELINE, *([val[0]] + val[1].children))
    result
  end
.,.,

# reduce 26 omitted

module_eval(<<'.,.,', 'parse.y', 61)
  def _reduce_27(val, _values, result)
     result = s(:TIME)
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 62)
  def _reduce_28(val, _values, result)
     result = s(:TIME_P)
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 68)
  def _reduce_29(val, _values, result)
     result = expand_PIPE_AND :left => val[0], :right => val[2]
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 69)
  def _reduce_30(val, _values, result)
     result = expand_PIPE_AND :left => val[0], :right => val[2]
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 70)
  def _reduce_31(val, _values, result)
     result = s(:PIPELINE, *val[0].children, *val[2].children)
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 71)
  def _reduce_32(val, _values, result)
     result = s(:PIPELINE, *val[0].children, val[2])
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 72)
  def _reduce_33(val, _values, result)
     result = s(:PIPELINE, val[0], *val[2].children)
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 73)
  def _reduce_34(val, _values, result)
     result = s(:PIPELINE, val[0], val[2])
    result
  end
.,.,

# reduce 35 omitted

# reduce 36 omitted

module_eval(<<'.,.,', 'parse.y', 78)
  def _reduce_37(val, _values, result)
     result = s(:COMMAND, *val[0].children, val[1])
    result
  end
.,.,

# reduce 38 omitted

module_eval(<<'.,.,', 'parse.y', 80)
  def _reduce_39(val, _values, result)
     result = s(:GROUP, *val[0].children, val[1])
    result
  end
.,.,

# reduce 40 omitted

module_eval(<<'.,.,', 'parse.y', 82)
  def _reduce_41(val, _values, result)
     result = s(:SUBSHELL, *val[0].children, val[1])
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 86)
  def _reduce_42(val, _values, result)
                                        result = val[1].type == :GROUP \
                                      ? val[1]
                                      : s(:GROUP,  val[1])

    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 93)
  def _reduce_43(val, _values, result)
                                        result = val[1].type == :SUBSHELL \
                                      ? val[1]
                                      : s(:SUBSHELL,  val[1])

    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 100)
  def _reduce_44(val, _values, result)
                                        result = s(:COMMAND,
                                               *(val.first.children + [s(:WORD, val.last)]))

    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 104)
  def _reduce_45(val, _values, result)
                                        result = s(:COMMAND,
                                               *(val.first.children + [s(:WORD, val.last)]))

    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 107)
  def _reduce_46(val, _values, result)
     result = s(:COMMAND, s(:WORD, val[0]))
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 110)
  def _reduce_47(val, _values, result)
     result = s(:REDIRECTIONS, *val[0].children, val[1])
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 111)
  def _reduce_48(val, _values, result)
     result = s(:REDIRECTIONS, val[0])
    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 121)
  def _reduce_49(val, _values, result)
                        unless match = val[0].match(/(\d+)[<>]&(\d+)\-/)
                      abort "expected `[n]<&digit-`, but got `#{val[0]}`"
                    end

                    n, digit = match.captures.map(&:to_i)
                    result = s(:MOVE_FD, n, digit)

    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 134)
  def _reduce_50(val, _values, result)
                         unless match = val[0].match(/(\d+)<>/)
                       abort "expected `[n]<>word`, but got `#{val[0]}`"
                     end

                     n = match.captures.first.to_i
                     result = s(:OPEN_RW, n, val[1])

    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 150)
  def _reduce_51(val, _values, result)
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

    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 170)
  def _reduce_52(val, _values, result)
                         unless match = val[0].match(/(\d+)[>>]/)
                       abort "expected `[n]>>word`, but got `#{val[0]}`"
                     end

                     n = match.captures.first.to_i
                     result = s(:APPEND, n, val[1])

    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 182)
  def _reduce_53(val, _values, result)
                              result = s(:APPEND_BOTH, val[1])

    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 189)
  def _reduce_54(val, _values, result)
                                result = s(:REDIRECT_BOTH, val[1])

    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 199)
  def _reduce_55(val, _values, result)
                          unless match = val[0].match(/(\d+)[<>]/)
                        abort "expected `[n]<word`, but got `#{val[0]}`"
                      end

                      n = match.captures.first.to_i
                      result = s(:REDIRECT, n, val[1])

    result
  end
.,.,

module_eval(<<'.,.,', 'parse.y', 207)
  def _reduce_56(val, _values, result)
                                    unless match = val[0].match(/(\d+)[<>]/)
                                  abort "expected `[n]>[|]word`, but got `#{val[0]}`"
                                end

                                n = match.captures.first.to_i
                                result = s(:REDIRECT_NOCLOBBER, n, val[1])

    result
  end
.,.,

def _reduce_none(val, _values, result)
  val[0]
end

  end   # class Parser
end   # module Msh


class Msh::Parser
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

  # Run the parser on a file
  def self.parse_file filename
    parser = Msh::Parser.new
    p parser.parse(File.read(filename))
  rescue ParseError
    abort $ERROR_INFO
  end

  # Parse each file passed as input (if any), or run interactively
  def self.start args = ARGV
    if args.size.positive?
      args.each do |file|
        abort "#{file} is not a file!" unless File.file?(file)
        parser = Msh::Parser.new
        p parser.parse(File.read(file))
      end
    else
      Msh::Parser.interactive
    end
  end
end
