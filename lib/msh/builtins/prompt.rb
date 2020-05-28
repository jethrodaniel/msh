# frozen_string_literal: true

require "msh/ansi"
require "msh/ext"

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
      Dir.pwd.green + " λ ".magenta.bold
    end
  end
end
