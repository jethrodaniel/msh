# lib = File.expand_path("lib", __dir__)
# $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require_relative "lib/msh/version"

Gem::Specification.new do |s|
  s.name     = "msh"
  s.version  = Msh::VERSION
  s.authors  = ["Mark Delk"].freeze
  s.email    = "jethrodaniel@gmail.com"
  s.summary  = "a ruby shell"
  s.description = <<~DESC
    Msh is an command language interpreter that executes commands read from
    standard input or from a file.

    It combines the "good" parts of *nix shells with the power of Ruby.
  DESC
  s.homepage = "https://github.com/jethrodaniel/msh"
  s.license  = "MIT"
  s.metadata = {
    "allowed_push_host" => "TODO: Set to 'https://rubygems.org'",
    "source_code_uri"   => s.homepage,
    "homepage_uri"      => s.homepage
  }
  s.files = %w[
    readme.md
    msh.gems
    license.txt
  ] + Dir.glob("man/man1/*") + Dir.glob("lib/**/*.rb") + Dir.glob("exe/*")

  s.bindir        = "exe"
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 2.5"

  s.add_dependency "reline", "~> 0.1.4"

  s.add_development_dependency "asciidoctor"
  s.add_development_dependency "bundler"
  s.add_development_dependency "fpm"
  s.add_development_dependency "parser"
  s.add_development_dependency "rake"
  s.add_development_dependency "rs"
  s.add_development_dependency "rubocop"
  s.add_development_dependency "yard"

  if RUBY_ENGINE == "ruby"
    s.add_development_dependency "pry"
    s.add_development_dependency "pry-byebug"
  end

  # s.post_install_message <<~MSG
  # MSG
end
