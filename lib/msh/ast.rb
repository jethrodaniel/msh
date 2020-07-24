# Minimal version of whitequark's excellent AST library: https://github.com/whitequark/ast
#
#     require "ast"
#
#     include AST:Sexp
#     s(:DIG, 10) #=> AST::Node.new(:DIG, 10)
#
# Seriously, use whitequark's if you can.
#
module Msh
  module AST
    class Node
      attr_reader :type, :children
      alias to_a children

      attr_reader :line, :column

      def initialize type, children, **opts
        @type = type
        @children = children
        opts.each { |k, v| instance_variable_set :"@#{k}", v }
      end

      def inspect indent = 0
        indented = "  " * indent
        sexp = "#{indented}s(:#{@type}"

        children.each do |child|
          sexp += if child.is_a?(Node)
                    ",\n#{child.inspect(indent + 1)}"
                  else
                    ", #{child.inspect}"
                  end
        end

        sexp += ")"

        sexp
      end

      def == other
        type == other.type && children == other.children
      end
    end

    module Sexp
      def s type, *children
        Node.new type, children
      end
    end
  end
end
