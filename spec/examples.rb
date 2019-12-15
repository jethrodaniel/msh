# frozen_string_literal: true

require "yaml"

# spec/fixtures/examples.yml uses this
require "ast"
include AST::Sexp

class Examples
  def self.passing
    examples.select { |_k, v| v[:valid] }
  end

  def self.failing
    examples.reject { |_k, v| v[:valid] }
  end

  def self.create_examples!
    puts "=== Creating example scripts ... ==="

    examples.each_with_index do |(code, data), index|
      good_or_bad = data[:valid] ? "good" : "bad"
      dir = Pathname.new(__dir__) + "fixtures/#{good_or_bad}"
      file = dir + "#{index}.msh"

      puts "-> #{file}"

      FileUtils.mkdir_p dir
      FileUtils.touch file

      File.open file, "w" do |f|
        # f.puts "#!/usr/bin/env msh\n\n"
        f.puts code
      end
      FileUtils.chmod "+x", file
    end

    puts "=== done ==="
  end

  def self.examples
    # https://github.com/puppetlabs/vmpooler/issues/240#issuecomment-354682704
    YAML.safe_load(File.read("spec/fixtures/examples.yml"), [Symbol])
        .dig(:examples)
  end
end
