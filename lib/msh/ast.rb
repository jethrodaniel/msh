module Msh
  # Minimal version of whitequark's excellent AST library: https://github.com/whitequark/ast
  #
  #     require "ast"
  #
  #     include AST:Sexp
  #     s(:DIG, 10) #=> AST::Node.new(:DIG, 10)
  #
  # Seriously, use whitequark's if you can.
  #
  module AST
    class Node
      attr_reader :type, :children, :line, :column
      alias to_a children

      def initialize type, children, **meta
        @type = type
        @children = children
        meta.each { |k, v| instance_variable_set :"@#{k}", v }
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
      def s type, *children, **meta
        Node.new type, children, **meta
      end
    end
  end
end
