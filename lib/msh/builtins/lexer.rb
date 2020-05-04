# frozen_string_literal: true

module Msh
  class Env
    # == name
    #
    # lexer - msh's lexer
    #
    # == synopsis
    #
    # *lexer* [_file_]...
    #
    # == description
    #
    # Run the lexer.
    def lexer *files
      Msh::Lexer.start files
      0
    end
  end
end
