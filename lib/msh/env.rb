# frozen_string_literal: true

require "irb"
require "pry"
require "pp"

require "msh/backports"
require "msh/error"
require "msh/configuration"
require "msh/ansi"

module Msh
  # An environment maintains the current environment variables of an
  # interpreter instance, as well as serving to host the methods used for
  # aliases and functions.
  #
  # When a command is called in the interpreter, it resolves that command in
  # the following order:
  #
  # - alises
  # - functions
  # - executables
  #
  # Msh handles environment variables, aliases, and functions by implementing
  # them as variables and methods on an Environment instance.
  #
  # NOTE: Methods prefixed with an underscore are hidden from `builtins`'s
  #       output.
  class Env
    include Msh::Colors

    class Error < Msh::Error; end

    @builtins = []

    def initialize
      @binding = binding
    end

    def _evaluate input
      # pry-byebug has an issue here, and would appear as a repl evaluated in
      # the wrong context here (in the AST gem, actually).  This is likely a
      # byebug-specific issue. IRB works fine here.
      begin
        e = @binding.eval(input, *@binding.source_location)
        e
      rescue NameError => e
        puts e.message
      end
    end
  end
end

require "msh/builtins/builtins"
require "msh/builtins/help"
require "msh/builtins/history"
require "msh/builtins/lexer"
require "msh/builtins/parser"
require "msh/builtins/prompt"
require "msh/builtins/quit"
require "msh/builtins/repl"
