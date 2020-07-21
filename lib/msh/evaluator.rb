require "msh/context"

module Msh
  class Evaluator
    def initialize
      @context = Context.new
    end

    def _call meth, *args, &block
      case @context.instance_eval { method(meth).arity }
      when 0
        @context.send meth, &block
      else
        @context.send meth, *args, &block
      end
    end
    alias call_no_exit_value _call

    def call meth, *args, &block
      ret = _call meth, *args, &block
      @context.instance_eval { @_ = ret }
      ret
    end

    def eval code
      ret = @context.instance_eval code
      @context.instance_eval { @_ = ret }
      ret
    end

    def has? meth
      @context.respond_to? meth
    end
  end
end
