# frozen_string_literal: true

require "msh/backports"
require "msh/errors"
require "msh/config"

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
    class Errors::EnvError < Errors::Error; end

    def initialize
      return if RUBY_ENGINE == "mruby"

      @binding = binding
    end

    # @note added just for testing
    def hi name
      puts "hello, #{name}"
    end

    def _evaluate input
      raise "unsupported" if RUBY_ENGINE == "mruby"

      # pry-byebug has an issue here, and would appear as a repl evaluated in
      # the wrong context here (in the AST gem, actually).  This is likely a
      # byebug-specific issue. IRB works fine here.

      e = @binding.eval(input, *@binding.source_location)
      e
    rescue NameError => e
      puts e.message
    end

    def run cmd, *args
      pid = fork do
        exec cmd, *args
      end
      Process.wait pid
      $CHILD_STATUS
    end
  end
end

# Dir.glob(File.join(Msh.root, "lib/msh/builtins", "**/*.rb"),

dir = File.dirname(File.realpath(__FILE__)) # rubocop:disable Style/Dir

%w[
  builtins
  cd
  help
  history
  lexer
  parser
  prompt
  quit
  repl
].each { |lib| require File.join(dir, "builtins", lib) }
