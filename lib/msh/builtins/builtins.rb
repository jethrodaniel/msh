# frozen_string_literal: true

module Msh
  class Env
    def builtins
      o = Object.new
      public_methods.reject { |m| o.respond_to? m }
                    .reject { |m| m.start_with? "_" }
                    .map(&:to_s)
                    .sort
                    .each { |m| puts m }
    end
  end
end
