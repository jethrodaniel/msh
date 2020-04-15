# frozen_string_literal: true

module Msh
  class Env
    # MAN
    # ```
    # ```
    def repl
      _evaluate "#\{@binding.#{Msh.configuration.repl}\}"
    end
  end
end
