# frozen_string_literal: true

require "msh/readline"

module Msh
  # The parser converts a series of tokens into an abstract syntax tree (AST).
  #
  # @example
  #     parser = Msh::Parser.new "fortune | cowsay"
  #     ast = \
  #       s(:PROG,
  #         s(:EXPR,
  #           s(:PIPELINE,
  #             s(:CMD,
  #               s(:WORD,
  #                 s(:LIT, "fortune"))),
  #             s(:CMD,
  #               s(:WORD,
  #                 s(:LIT, "cowsay"))))))
  #     parser.parse == ast #=> true
  #
  class Parser
    # Run the parser interactively, i.e, run a loop and parse user input.
    def self.interactive
      while line = ::Msh::Readline.readline("parser> ")
        if %w[q quit exit].include? line
          puts "goodbye! <3"
          return
        end

        lexer = ::Msh::Lexer.new line
        parser = new(TokenStream.new(lexer))

        begin
          puts parser.parse
        rescue Errors::ParseError => e
          puts e.message
        end
      end
    end

    # Parse each file passed as input (if any), or run interactively
    def self.start args = ARGV
      return interactive if args.empty?

      args.each do |file|
        raise Errors::ParseError, "#{file} is not a file!" unless File.file?(file)

        parser = new File.read(file)
        puts parser.parse
      end
    end

    def error
      raise Errors::ParseError, "#{file} is not a file!" unless File.file?(file)
    end
  end
end
