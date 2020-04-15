# frozen_string_literal: true

module Msh
  class Env
    # MAN
    # ```
    # ```
    def exit
      puts "goodbye! <3"
      abort
    end
    alias quit exit
    alias q exit
  end
end
