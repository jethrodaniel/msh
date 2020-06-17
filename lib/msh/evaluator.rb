# frozen_string_literal: true

require "msh/context"

module Msh
  class Evaluator
    def initialize
      @context = Context.new
    end

    def call meth, *args, &block
      case @context.instance_eval { method(meth).arity }
      when 0
        @context.send meth, &block
      else
        @context.send meth, *args, &block
      end
    end

    def eval code
      @context.instance_eval code
    end

    def has? meth
      @context.respond_to? meth
    end
  end
end
