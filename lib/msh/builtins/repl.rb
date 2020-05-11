# frozen_string_literal: true

module Msh
  class Env
    # == name
    #
    # repl - easily access Msh's Ruby interpretor
    #
    # == synopsis
    #
    # *repl*
    #
    # == description
    #
    # This is equivalent to
    #
    #     #{binding.irb}  # if using IRB
    #     #{binding.pry}  # if using Pry
    #
    def repl
      require Msh.configuration.repl.to_s
      @binding.send Msh.configuration.repl
      0
    end
  end
end
