# frozen_string_literal: true

module Msh
  class Env
    def quit code = 1
      puts "goodbye! <3"
      exit! code
    end
    alias exit quit
    alias q quit
  end
end
