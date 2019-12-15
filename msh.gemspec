# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "msh/version"

Gem::Specification.new do |spec|
  spec.name     = "msh"
  spec.version  = Msh::VERSION
  spec.authors  = ["Mark Delk"]
  spec.email    = ["jethrodaniel@gmail.com"]

  spec.summary  = "msh is a ruby shell"
  spec.homepage = "https://github.com/jethrodaniel/msh"
  spec.license  = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the
  # 'allowed_push_host' to allow pushing to a single host or delete this
  # section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = spec.homepage
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # :r !git ls-files
  spec.files = %w[
    .github/workflows/ci.yml
    .gitignore
    .rspec
    .rubocop.yml
    .yardopts
    TODO.txt
    exe/msh
    ext/msh/extconf.rb
    gems.locked
    gems.rb
    lib/msh.rb
    lib/msh/ast.rb
    lib/msh/configuration.rb
    lib/msh/error.rb
    lib/msh/interpreter.rb
    lib/msh/parse.l
    lib/msh/parse.y
    lib/msh/version.rb
    license.txt
    msh.gemspec
    rakefile
    readme.erb.md
    readme.md
    spec/examples.rb
    spec/fixtures/examples.yml
    spec/msh/ast_spec.rb
    spec/msh/configuration_spec.rb
    spec/msh/interpreter_spec.rb
    spec/msh/lexer_spec.rb
    spec/msh/parser_spec.rb
    spec/msh_spec.rb
    spec/spec_helper.rb
    templates/msh/fulldoc/html/app.js.erb
    templates/msh/fulldoc/html/app.scss
    templates/msh/fulldoc/html/assets/github.svg
    templates/msh/fulldoc/html/assets/ruby_logo_shiny.svg
    templates/msh/fulldoc/html/assets/ruby_logo_simple.svg
    templates/msh/fulldoc/html/assets/rubygems_logo.svg
    templates/msh/fulldoc/html/components/clock.js
    templates/msh/fulldoc/html/components/rotating.js
    templates/msh/fulldoc/html/index.erb
    templates/msh/fulldoc/html/package.json
    templates/msh/fulldoc/html/webpack.config.js
    templates/msh/fulldoc/html/yarn.lock
    templates/msh/fulldoc/setup.rb
    templates/msh/fulldoc/text/index.erb
  ]

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.5"

  spec.add_dependency "racc", "~> 1.4"
  spec.add_dependency "reline", "~> 0.1.3"
  spec.add_dependency "rexical", "~> 1.0"

  # TODO: make these optional
  # spec.add_dependency "activesupport", "~> 6.0"
  # spec.add_dependency "pry", "~> 0.12.2"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "redcarpet", "~> 3.5"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 0.80.0"
  spec.add_development_dependency "yard", "~> 0.9.24"

  spec.extensions = ["ext/msh/extconf.rb"]
end
