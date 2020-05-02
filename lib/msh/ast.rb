# frozen_string_literal: true

require "ast"

module Msh
  # This AST class contains more specialized AST command representations, like
  #
  #     a = Command.new :words => %w[echo hi]
  #     b = Command.new :words => %w[cowsay]
  #
  #     cond = And.new :left => a, :right => b
  #
  #     p = Pipeline.new :piped => [cond, b]
  #
  module AST
    # subclassing AST::Node to provide meta-information
    class Node < ::AST::Node
      # @return [Integer]
      attr_reader :line

      # @return [Integer]
      attr_reader :column
    end
  end
end
