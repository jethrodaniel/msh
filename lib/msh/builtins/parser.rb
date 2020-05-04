# frozen_string_literal: true

module Msh
  class Env
    # == name
    #
    # parser - msh's parser
    #
    # == synopsis
    #
    # *parser* [_file_]...
    #
    # == description
    #
    # Run the parser.
    def parser *files
      Msh::Parser.start files
      0
    end
  end
end
