module Msh
  module Errors
    class Error < StandardError; end
    class ParseError       < Error; end
    class InterpreterError < Error; end
    class LexerError       < Error; end
    class ReplError        < Error; end
    class LoggerError      < Error; end
  end
end
