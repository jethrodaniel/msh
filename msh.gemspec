# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "msh/version"

Gem::Specification.new do |spec|
  spec.name     = "msh"
  spec.version  = Msh::VERSION
  spec.authors  = ["Mark Delk"]
  spec.email    = ["jethrodaniel@gmail.com"]

  spec.summary  = "a ruby shell"
  spec.homepage = "https://github.com/jethrodaniel/msh"
  spec.license  = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the
  # 'allowed_push_host' to allow pushing to a single host or delete this
  # section to allow pushing to any host.
  unless spec.respond_to?(:metadata)
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.metadata = {
    "allowed_push_host" => "TODO: Set to 'https://rubygems.org'",
    "source_code_uri" => spec.homepage,
    "homepage_uri" => spec.homepage
  }

  # Don't use the typical `git ls-files` here, since not everyplace has git.
  #
  # Ship the minimal amount of files needed for production.
  spec.files = %w[
    exe/msh
    gems.locked
    gems.rb
    lib/msh.rb
    lib/msh/ast.rb
    lib/msh/configuration.rb
    lib/msh/documentation.rb
    lib/msh/error.rb
    lib/msh/extensions.rb
    lib/msh/gemspec.rb
    lib/msh/interpreter.rb
    lib/msh/lexer.rb
    lib/msh/parser.rb
    lib/msh/version.rb
    license.txt
    man/man1/msh-help.1
    man/man1/msh-history.1
    man/man1/msh-lexer.1
    man/man1/msh-parser.1
    man/man1/msh.1
    msh.gemspec
    readme.md
  ]

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.4"

  spec.add_dependency "ast", "~> 2.4"
  # spec.add_dependency "reline", "~> 0.1.3"

  # spec.add_dependency "activesupport", "~> 6.0"

  spec.add_development_dependency "asciidoctor", "~> 2.0"
  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "pry-byebug", "~> 3.8"
  spec.add_development_dependency "racc", "~> 1.4"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rexical", "~> 1.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 0.80.0"
  spec.add_development_dependency "yard", "~> 0.9.24"
end
