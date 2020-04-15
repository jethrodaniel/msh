# frozen_string_literal: true

module Msh
  class Env
    # MAN
    # ```
    # ```
    def parser *files
      Msh::Parser.start files
      0
    end
  end
end
