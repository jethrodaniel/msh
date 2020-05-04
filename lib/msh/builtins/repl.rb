# frozen_string_literal: true

module Msh
  class Env
    # MAN
    # ```
    # ```
    def repl
      @binding.send Msh.configuration.repl
    end
  end
end
