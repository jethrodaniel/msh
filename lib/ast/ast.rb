# frozen_string_literal: true

# Minimal version of whitequark's excellent AST library: https://github.com/whitequark/ast
#
#     require "ast"
#
#     include AST:Sexp
#     s(:DIG, 10) #=> AST::Node.new(:DIG, 10)
#
module AST
  class Node
    attr_reader :type, :children

    def initialize type, children
      @type = type
      @children = children
    end

    def to_s indent = 0
      if children.size == 1 && children.first.is_a?(String)
        "#{' ' * indent}s(:#{type}, #{children.first.inspect})"
      else
        ch = children.map do |c|
          if c.is_a? Node
            "\n#{c.to_s(indent + 2)}"
          else
            "\n#{' ' * (indent + 2)}#{c}"
          end
        end.join(", ")

        if ch == ""
          "#{' ' * indent}s(:#{type})"
        else
          "#{' ' * indent}s(:#{type}, #{ch})"
        end
      end
    end
  end

  module Sexp
    def s type, *children
      Node.new type, children
    end
  end
end
