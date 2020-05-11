# frozen_string_literal: true

# bundle exec yard doctest

require "msh"

# let us use `s(:TOKEN, ...)` in doctests
include ::AST::Sexp # rubocop:disable Style/MixinUsage
