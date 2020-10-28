# lib = File.expand_path("lib", __dir__)
# $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require_relative "lib/msh/version"

Gem::Specification.new do |spec|
  spec.name     = "msh"
  spec.version  = Msh::VERSION
  spec.authors  = ["Mark Delk"].freeze
  spec.email    = "jethrodaniel@gmail.com"
  spec.summary  = "a ruby shell"
  spec.description = <<~DESC
    Msh is an command language interpreter that executes commands read from
    standard input or from a file.

    It combines the "good" parts of *nix shells with the power of Ruby.
  DESC
  spec.homepage = "https://github.com/jethrodaniel/msh"
  spec.license  = "MIT"
  spec.metadata = {
    "allowed_push_host" => "TODO: Set to 'https://rubygems.org'",
    "source_code_uri"   => spec.homepage,
    "homepage_uri"      => spec.homepage
  }
  spec.files = %w[
    readme.md
    msh.gemspec
    license.txt
  ] + Dir.glob("man/man1/*") + Dir.glob("lib/**/*.rb") + Dir.glob("exe/*")

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 2.5"

  spec.add_dependency "reline", "~> 0.1.4"

  spec.add_development_dependency "asciidoctor"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "fpm"
  spec.add_development_dependency "parser"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "yard"

  if RUBY_ENGINE == "ruby"
    spec.add_development_dependency "pry"
    spec.add_development_dependency "pry-byebug"
  end

  # spec.post_install_message <<~MSG
  # MSG
end
