# frozen_string_literal: true

module Msh
  class Env
    # == name
    #
    # cd - change directories
    #
    # == synopsis
    #
    # *cd* [__dir__]
    #
    # == description
    #
    #  Changes the shell's current directory, and sets the following env vars:
    #
    #  - `OLDPWD` - the last directory the shell was in
    #  - `PWD` - the directory the shell is currently in
    #
    # If `dir` is `-`, the destination will be be `${USER}
    def cd dir = nil
      last = ENV["OLDPWD"]
      ENV["OLDPWD"] = Dir.pwd
      case dir
      when "-"
        unless last
          puts "`OLDPWD` not yet set!"
          return 1
        end

        Dir.chdir last
      when nil
        Dir.chdir ENV["HOME"]
      else
        Dir.chdir dir
      end
      ENV["PWD"] = Dir.pwd
      0
    end
  end
end
