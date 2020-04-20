# frozen_string_literal: true

class Examples
  def self.passing
    examples.select { |_k, v| v[:valid] }
  end

  def self.failing
    examples.reject { |_k, v| v[:valid] }
  end

  def self.examples
    # https://github.com/puppetlabs/vmpooler/issues/240#issuecomment-354682704
    YAML.safe_load(File.read("spec/fixtures/examples.yml"), [Symbol])
        .dig(:examples)
  end
end
