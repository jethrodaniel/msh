# frozen_string_literal: true

require "msh/cli"
require "msh/documentation"
require "msh/repl"

# Msh is a Ruby shell.
#
# It supports a basic subset of shell, including
#
#   - [x] redirection `a 2>&1 > out.log`
#   - [ ] conditionals `a || b && c`
#   - [x] commands `a; b;`
#   - [ ] grouping `a; {b}`
#   - [ ] subshells `(a) && {b || c; }`
#   - [x] pipes `a | b`
#
# It uses Ruby to handle variables, functions, and aliases, and allows for
# Ruby interpolation anywhere in the source.
#
# ```
# $ echo π ≈ #{Math::PI} . |cowsay
#  _________________________
# < π ≈ 3.141592653589793 . >
#  -------------------------
#         \   ^__^
#          \  (oo)\_______
#             (__)\       )\/\
#                 ||----w |
#                 ||     ||
# ```
#
# Msh operates more or less like so:
#
# 1. `msh` executable calls {Msh::Repl::Ansi.initialize}
#
#     while line = gets.chomp
#       line = interpreter.preprocess line
#       lexer = Msh::Lexer.new line
#       parser = Msh::Parser.new lexer.tokens
#       interpreter.process parser.parse
#     end
#
# 1. preprocessing is done be evaling any string interpolation (`#{}`).
#
#     def preprocess line
#       environment.eval line #=> same string, interpolated
#     end
#
# 1. lexing breaks the input up into tokens
#
#     lexer = Msh::Lexer.new "fortune | cowsay"
#     lexer.tokens.map &:to_s
#     => ["[1:1-7][WORD, 'fortune']",
#         "[1:9-9][PIPE, '|']",
#         "[1:11-16][WORD, 'cowsay']",
#         "[1:17-17][EOF, '']"]
#
# 1. parsing combines tokens into grammar rules
#
#     parser = Msh::Parser.new lexer.tokens
#     parser.parse
#     => s(:EXPR,
#       s(:PIPELINE,
#         s(:COMMAND,
#           s(:WORD, "fortune")),
#         s(:COMMAND,
#           s(:WORD, "cowsay"))))
#
# 1. the AST is interpreted by an {Msh::Interpreter} instance.
#
# Command resolution in the interpreter is as follows:
#
# 	1. check aliases
# 	1. check functions
# 	1. check executables
#
# TODO: finish this
module Msh
  # Entry point for the `msh` command.
  #
  # Parses options/commands, then runs either interactively or on files.
  #
  # If the `NO_READLINE` environment variable is set, readline won't be used.
  def self.start
    Msh::Documentation.setup_manpath!
    Msh::CLI.handle_options!

    if ARGV.size.zero?
      if ENV["NO_READLINE"]
        Msh::Repl::Simple.new
      else
        Msh::Repl::Ansi.new
      end
    else
      interpreter = Msh::Interpreter.new
      ARGV.each do |file|
        lexer = Msh::Lexer.new File.read(file)
        parser = Msh::Parser.new lexer.tokens
        interpreter.process parser.parse
      end
    end
  end
end
