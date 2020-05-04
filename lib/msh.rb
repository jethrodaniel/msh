# frozen_string_literal: true

module Msh
  def self.root
    Pathname.new(__dir__).join '..'
  end
end

require "msh/cli"
require "msh/documentation"
require "msh/repl"

# == Msh is a Ruby shell.
#
# It supports a subset of `sh`/`bash`, including
#
#   - [x] redirection `a 2>&1 > out.log`
#   - [ ] conditionals `a || b && c`
#   - [x] commands `a; b;`
#   - [ ] grouping `a; {b}`
#   - [ ] subshells `(a) && {b || c; }`
#   - [x] pipes `a | b`
#   - [ ] command substitution `a 'b' c` (but use backticks, not single qoutes)
#   - [ ] process substitution `<(a | b)`
#
# It uses Ruby to handle variables, functions, and aliases, and allows for
# Ruby interpolation anywhere in the source.
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
# Unlike other shells, Msh doesn't have functions or variables builtin to the
# language, rather, it tasks that to it's host, or implementation, language
# (here, Ruby).
#
# The host language is available via a REPL at with the `repl` command, and
# additionally processes string interpolation in all commands.
#
#     $ repl
#     irb> ... quit
#     $ echo the time is now #{Time.now}
#
# ==== Functions
#
# Instead of functions, Msh just calls Ruby methods
#
#     echo #{def hello name; puts "hello, #{name}"; end}
#     hello world #=> prints "hello, world"
#
# Similarly, builtins and aliases are just Ruby methods as well.
#
#     $ builtins
#     $ aliases
#
# ==== Variables
#
# Variables in the REPL correspond directly to environment variables.
#
#     $ RAILS_ENV=production bundle exec rails
#     $ repl
#     irb> RAILS_ENV='production' # this is like `export VAR=...`
#     $ bundle exec rails
#
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
      Msh::Repl.new
    else
      interpreter = Msh::Interpreter.new
      ARGV.each do |file|
        interpreter.interpret File.read(file)
      end
    end
  end
end
