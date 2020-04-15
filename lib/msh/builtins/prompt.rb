# frozen_string_literal: true

module Msh
  class Env
    # MAN
    # ```
    # ```
    def prompt
      Paint["msh ", GREEN, :bright] + Paint["λ ", PURPLE, :bright]
    end
  end
end
