# frozen_string_literal: true

require "ast"
require "msh/lexer"

module Msh
  class Parser
    include ::AST::Sexp

    class Error < StandardError
    end

    attr_reader :lexer

    def initialize
      @lexer = Msh::Lexer.new
    end

    def parse code
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

require "readline"
Msh::Parser.interactive
