# frozen_string_literal: true

require "ast"

module Msh
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
