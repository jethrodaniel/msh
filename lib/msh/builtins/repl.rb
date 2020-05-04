# frozen_string_literal: true

module Msh
  class Env
    # MAN
    # ```
    # ```
    def repl
      require Msh.configuration.repl.to_s
      @binding.send Msh.configuration.repl
    end
  end
end
