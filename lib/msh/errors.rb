# frozen_string_literal: true

module Msh
  module Errors
    class Error < StandardError
    end

    # Error to use if no more specialized error class is available
    class BasicError < Error
    end
  end
end
