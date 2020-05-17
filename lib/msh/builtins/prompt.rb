# frozen_string_literal: true

module Msh
  class Env
    # == name
    #
    # prompt - msh's prompt
    #
    # == synopsis
    #
    # *prompt*
    #
    # == description
    #
    # Msh's prompt is set via this method.
    #
    # ```
    # λ echo #{def prompt; "$ "; end}
    # prompt
    # $ ...
    # ```
    def prompt
      Paint[Dir.pwd, :green] + Paint[" λ ", :magenta, :bright]
    end
  end
end
