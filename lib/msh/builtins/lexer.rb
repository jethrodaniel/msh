# frozen_string_literal: true

module Msh
  class Env
    # MAN
    # ```
    # ```
    def lexer *files
      Msh::Lexer.start files
      0
    end
  end
end
