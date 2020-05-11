# frozen_string_literal: true

class Examples
  def self.lexer_passing
    examples.select { |_k, v| v[:lexer_valid] }
  end

  def self.lexer_failing
    examples.reject { |_k, v| v[:lexer_valid] }
  end

  def self.parser_passing
    examples.select { |_k, v| v[:parser_valid] }
  end

  def self.parser_failing
    examples.reject { |_k, v| v[:parser_valid] }
  end

  def self.interpreter_passing
    examples.select { |_k, v| v[:interpreter_valid] }
  end

  def self.interpreter_failing
    examples.reject { |_k, v| v[:interpreter_valid] }
  end

  def self.each &block
    examples.each(&block)
  end

  def self.examples
    # https://github.com/puppetlabs/vmpooler/issues/240#issuecomment-354682704
    YAML.safe_load(File.read("spec/fixtures/examples.yml"), [Symbol])
        .dig(:examples)
  end
end
