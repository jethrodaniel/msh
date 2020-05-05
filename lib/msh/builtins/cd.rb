# frozen_string_literal: true

module Msh
  class Env
    # == name
    #
    # cd - change directories
    #
    # == synopsis
    #
    # *cd* [_dir]
    #
    # == description
    #
    #  Changes the shell's current directory
    def cd dir = nil
      last = ENV["OLDPWD"]
      ENV["OLDPWD"] = Dir.pwd
      case dir
      when "-"
        raise "`OLDPWD` not yet set!" unless last

        Dir.chdir last
      when nil
        Dir.chdir ENV["HOME"]
      else
        Dir.chdir dir
      end
      ENV["PWD"] = Dir.pwd
    end
  end
end
