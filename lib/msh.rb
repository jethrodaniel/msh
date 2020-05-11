# frozen_string_literal: true

require "pathname"

module Msh
  def self.root
    Pathname.new(__dir__).join ".."
  end
end

require "msh/cli"
require "msh/repl"

# == name
#
# msh - a ruby shell
#
# == synopsis
#
# *msh* [_options_]... [_file_]...
#
# == description
#
# It supports a subset of `sh`/`bash`, including
#
#   - [ ] redirection `a 2>&1 > out.log`
#   - [ ] conditionals `a || b && c`
#   - [x] commands `a; b;`
#   - [ ] grouping `a; {b}`
#   - [ ] subshells `(a) && {b || c; }`
#   - [x] pipes `a | b`
#   - [ ] command substitution $(a 'b' c) (but no backticks, just `$()`)
#   - [ ] process substitution `<(a | b)`
#   - [x] local shell variables, and syntax to manipulate environment variables
#
# It uses Ruby to handle functions, and aliases, and allows for Ruby
# interpolation anywhere in the source.
#
# ```
# $ echo π ≈ #{Math::PI} | cowsay
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
# Unlike other shells, Msh doesn't have functions or aliases builtin to the
# language, rather, it tasks that to it's host, or implementation, language
# (here, Ruby).
#
# The host language's REPL is available via `repl` builtin, and additionally
# processes string interpolation in all commands.
#
#     $ repl
#     irb> foo = "bar"
#     irb> quit
#     $ echo #{foo} #=> bar
#
# === Functions
#
# Instead of functions, Msh just calls Ruby methods
#
#     $ echo #{def hello name; puts "hello, #{name}"; end}
#     $ hello world #=> prints "hello, world"
#
# Similarly, builtins and aliases are just Ruby methods as well.
#
#     $ builtins
#
# == options
#
# *-h, --help*::
#   Show usage information.
#
# *-V, --version*::
#   Show the version.
#
# *--copyright, --license*::
#   Show the copyright.
#
# *-c <command>*::
#   Run a command string as input.
#
# == resources
#
# *issue tracker*:: https://github.com/jethrodaniel/msh/issues?q=is%3Aopen.
# *source code*:: https://github.com/jethrodaniel/msh
module Msh
  # Entry point for the `msh` command.
  #
  # Parses options/commands, then runs either interactively or on files.
  def self.start
    Msh::CLI.handle_options!

    if ARGV.size.zero?
      Msh::Repl.new
    else
      interpreter = Msh::Interpreter.new
      ARGV.each do |file|
        interpreter.interpret File.read(file)
      end
    end
  end
end
