# frozen_string_literal: true

module Msh
  class Env
    # @todo fish shell like abbreviation
    #
    # ```
    # $ fish
    # Welcome to fish, the friendly interactive shell
    # ~/c/r/msh (dev %=)
    # ```
    def prompt
      Paint[Dir.pwd, :green] + Paint[" λ ", :magenta, :bright]
    end
  end
end
