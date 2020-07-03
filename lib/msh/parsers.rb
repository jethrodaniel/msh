# frozen_string_literal: true

require "msh/readline"

module Msh
  # require "msh/parsers/simple"
  # require "msh/parsers/peg"
  # require "msh/parsers/kpeg"
  # require "msh/parsers/parslet"
  #
  # The parser converts a series of tokens into an abstract syntax tree (AST).
  #
  # @example
  #     parser = Msh::Parsers::Simple.new "fortune | cowsay"
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
  # The grammar parsed is as follows
  #
  # ```
  # program:    expr | expr SEMI | expr SEMI program
  # expr:       and_or | pipeline
  # and_or:     pipeline AND pipeline | pipeline OR pipeline
  # pipeline:   command PIPE pipeline | command
  # command:    cmd_part command | cmd_part
  # cmd_part:   redirect | word | assignment
  # assignment: word EQ word
  # word:       word_type word | word_type
  # word_type:  WORD | INTERP | SUB | VAR
  # redirect:   REDIRECT_OUT | REDIRECT_IN
  # ```
  #
  module Parsers
    def self.input_loop
      while line = ::Msh::Readline.readline("parser> ")
        if %w[q quit exit].include? line
          puts "goodbye! <3"
          return
        end
        yield line
      end
    end

    # Parse each file passed as input (if any), or run interactively
    def self.start parser_class, args = ARGV
      return parser_class.interactive if args.empty?

      args.each do |file|
        raise Errors::ParseError, "#{file} is not a file!" unless File.file?(file)

        parser = parser_class.new File.read(file)
        p parser.parse
      end
    end

    # def error
    #   raise Errors::ParseError, "#{file} is not a file!" unless File.file?(file)
    # end
  end
end
