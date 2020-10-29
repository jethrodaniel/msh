require "msh"

# module Msh
#   module DSL
#     def msh &block
#       Context.class_eval(&block)
#     end
#   end
# end

# include Msh::DSL

# Msh::DSL.command


# macros are expanded when called, like traditional aliases
macro :dir,  "tree -L 1 --dirsfirst -C"
macro :dira, "#{macro[:dira]} -C"
macro :now,  "date +%Y%m%d%H%M%S"
macro :duh,  'find . -maxdepth 1 -exec du -sh {} \;'

# `symlink` is like an alias that passes all arguments
symlink :g  => :git,
        :b  => "bundle exec",
        :r  => "bundle exec rails",
        :vo => "vim -O",
        :vp => "vim -p"

# instead of $PATH`
path << '~/bin'

def install pkg # instead of `function`
end
