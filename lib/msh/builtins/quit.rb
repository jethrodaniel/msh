# frozen_string_literal: true

module Msh
  class Env
    def quit
      puts "goodbye! <3"
      abort
    end
    alias exit quit
    alias q quit
  end
end
