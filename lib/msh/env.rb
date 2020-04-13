# frozen_string_literal: true

require "irb"
require "pry"
require "pp"

require "msh/error"
require "msh/configuration"
require "msh/ansi"

# prevent IRB from polluting Readline history
# IRB.conf[:SAVE_HISTORY] = nil

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
      e = @binding.eval("\"#{input}\"", *@binding.source_location)
      e
    end

    def builtins
      o = Object.new
      public_methods.reject { |m| o.respond_to? m }
                    .reject { |m| m.start_with? "_" }
                    .map(&:to_s)
                    .sort
                    .each { |m| puts m }
    end

    def prompt
      Paint["msh ", GREEN, :bright] + Paint["λ ", PURPLE, :bright]
    end

    def history
      size = 3
      Readline::HISTORY.to_a.tap do |h|
        size = h.size.to_s.chars.size
      end.each.with_index(1) do |e, i|
        puts "#{i.to_s.ljust(size, ' ')} #{e}"
      end
      0
    end
    alias hist history

    def help *topics
      cmd = if topics.empty?
              %w[man msh]
            else
              %w[man] + topics.map { |t| "msh-#{t}" }
            end
      run(*cmd)
    end

    def lexer *files
      Msh::Lexer.start files
      0
    end

    def parser *files
      Msh::Parser.start files
      0
    end

    def repl
      _evaluate "#\{@binding.#{Msh.configuration.repl}\}"
    end

    def exit
      puts "goodbye! <3"
      abort
    end
    alias quit exit

    private

    # Execute a command via `fork`, wait for the command to finish
    #
    # TODO: spawn, so this can be more platform-independent
    #
    # @param args [Array<String>] args to execute
    # @return [Void]
    def run *args
      unless args.all? { |a| a.is_a? String }
        abort "expected Array<String>, got `#{args.class}:#{args.inspect}`"
      end

      pid = fork do
        exec *args
      rescue Errno::ENOENT => e
        puts e.message
      end

      Process.wait pid

      $CHILD_STATUS.exitstatus
    end
  end
end
