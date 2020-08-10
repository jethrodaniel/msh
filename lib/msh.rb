require "English"

require "msh/backports"
require "msh/core_extensions"
require "msh/cli"
require "msh/repl"

# == NAME
#
# msh - a ruby shell
#
# == SYNOPSIS
#
# *msh* [_options_]... [_file_]...
#
# == DESCRIPTION
#
# Msh is an command language interpreter that executes commands read from
# standard input or from a file.
#
# It combines the "good" parts of *nix shells with the power of Ruby.
#
# Msh's goal is the same as that of Ruby
#
# [quote, Yukihiro Matsumoto]
# ____
# For me the purpose of life is partly to have joy. Programmers often feel
# joy when they can concentrate on the creative side of programming, So Ruby
# is designed to make programmers happy.
# ____
#
# It supports a subset of `sh`/`bash`, basically just the _essential_ parts.
#
#
# ```
#        feature                       example
# ┌───┬─────────────────────────────┬──────────────────────────────────────┐
# │ ✓ │ redirect output             │ a > b                                │
# │ ✓ │ append output               │ a >> b                               │
# │ ✓ │ redirect input              │ a < b                                │
# │   │ redirect to file descriptor │ a 2>&1                               │
# │ ~ │ conditionals                │ a || b && c                          │
# │ ✓ │ commands                    │ a; b;                                │
# │   │ grouping                    │ a; {b || c}                          │
# │   │ subshells                   │ (a)                                  │
# │ ✓ │ pipes*                      │ a | b                                │
# │   │ command substitution        │ $(a 'b' c)                           │
# │   │ process substitution        │ <(a | b)                             │
# │   │ local variables             │ a = 2                                │
# │ ✓ │ variable interpolation      │ echo $HOME                           │
# │ ✓ │ environment variables       │ a=b a b                              │
# │   │ aliases                     │ alias g 'git'                        │
# │ ✓ │ functions                   │ repl; def foo;puts :bar;end; ^D foo  │
# └───┴─────────────────────────────┴──────────────────────────────────────┘
# ┌───┬─────────────────────────────┐┌───┬─────────────────────────────┐
# │ ✓ │ feature fully supported     ││   │ feature pending             │
# │ ~ │ feature sorta supported     ││ x │ won't support               │
# └───┴─────────────────────────────┘└───┴─────────────────────────────┘
# ```
#
# **NOTE**: redirection and pipes won't work in the executable version of msh
#   until MRuby supports `IO#reopen`.
#
# **NOTE**: this is an intentionally small subset of `sh`, for now.
#
# It allows for interpolation in words
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
# The underlying REPL is available via the `repl` builtin. It's the same
# context as used during interpolation.
#
# ```
# $ repl
# enter some ruby (sorry, no multiline)
# > def foo; "bar"; end
# => :foo
# > ^D
# $ echo foo#{foo}
# foo bar
# $ echo #{self}
# <Msh::Context:0x0000557a7f0b6f68>
# ```
#
# Functions are just method calls on that same REPL context.
#
# == Examples
#
# Filter commands
#
# ```
# $ repl
# enter some ruby (sorry, no multiline)
# > def upcase; ARGF.each_line { |l| puts l.upcase }; end
# => :upcase
# > ^D
# $ echo hi | upcase
# HI
# ```
#
# Changing the prompt
#
# ```
# $ repl
# enter some ruby (sorry, no multiline)
# > def prompt; "% "; end
# => "% "
# > ^D
# %
# ```
#
# == Builtins
#
# Msh's usage of the term _builtin_ is a bit loose here - _builtins_ can fork
# and exec if they want.
#
# Plus, since functions are just method calls to a single object, there's a
# number of _builtins_ already available, such as `puts`, `print`,
# `respond_to?`, etc.
#
# ```
# ┌───────────────────┬─────────────────────────────────────────────────┐
# │ parser [files]... │ Run Msh's parser on input files, or from stdin  │
# │ lexer  [files]... │ Run Msh's lexer on input files, or from stdin   │
# │ help  [topics]... │ Equivalent to 'man msh-topic ...' or 'man msh'  │
# │ cd                │ Change directory, respects '-', 'PWD/OLDPWD'    │
# └───────────────────┴─────────────────────────────────────────────────┘
# ```
#
# === TODO
#
# **Note**: not a comprehensive list, by any means.
#
# ```
# ┌───┬───────────────────────────────────────────────────────────────────┐
# │   │`source file.msh`                                                  │
# │ ~ │ config files                                                      │
# │   │ interrupt handling                                                │
# │   │ control flow such as `if/else/while/loop`                         │
# │   │ tab-completion                                                    │
# │   │ pretty colors                                                     │
# └───┴───────────────────────────────────────────────────────────────────┘
# ```
#
# == Options
#
# *-h, --help*::
#   Show usage information.
#
# *-V, --version*::
#   Show the version.
#
# *-c <command>*::
#   Run a command string as input.
#
# == Copying
#
# Copyright \(C) 2020 Mark Delk.
# Free use of this software is granted under the terms of the MIT License.
#
# == Resources
#
# *issue tracker*:: https://github.com/jethrodaniel/msh/issues?q=is%3Aopen.
# *source code*:: https://github.com/jethrodaniel/msh
# *releases*:: https://github.com/jethrodaniel/msh/releases
#
# == Shameless Plug
#
# Donations are appreciated. Stay safe y'all.
#
module Msh
  def self.root
    lib = File.dirname(File.realpath(__FILE__)) # rubocop:disable Style/Dir
    File.realpath(File.join(lib, "../.."))
  end

  # Entry point for the `msh` command.
  #
  # Parses options/commands, then runs either interactively or on files.
  def self.start
    Msh::CLI.handle_options!

    return Msh::Repl.new if ARGV.size.zero?

    interpreter = Msh::Interpreter.new

    ARGV.each do |file|
      abort "`#{file}` not found" unless File.file?(file)
      interpreter.interpret File.read(file)
    end
  end
end
