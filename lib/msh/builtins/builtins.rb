# frozen_string_literal: true

module Msh
  class Env
    def builtins
      o = Object.new
      public_methods.reject { |m| o.respond_to? m }
                    .reject { |m| m.start_with? "_" }
                    .sort
                    .each { |m| puts m }
    end
  end
end
