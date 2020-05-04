# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "msh/version"
require "msh/gemspec"

Gem::Specification.new do |spec|
  spec.name     = Msh::NAME
  spec.version  = Msh::VERSION
  spec.authors  = Msh::AUTHORS
  spec.email    = Msh::EMAIL
  spec.summary  = Msh::SUMMARY
  spec.homepage = Msh::HOMEPAGE
  spec.license  = Msh::LICENSE

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
    readme.md
    msh.gemspec
    license.txt
    exe/msh
  ] + Dir.glob("man/man1/*") + Dir.glob("lib/**/*.rb")

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.4"

  spec.add_dependency "ast", "~> 2.4"
  spec.add_dependency "paint", "~> 2.2"
  # spec.add_dependency "reline", "~> 0.1.3"

  spec.add_development_dependency "asciidoctor"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "yard-doctest"
end
