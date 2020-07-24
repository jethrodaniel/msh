# bundle exec yard doctest

require "msh"

# let us use `s(:TOKEN, ...)` in doctests
include Msh::AST::Sexp # rubocop:disable Style/MixinUsage
