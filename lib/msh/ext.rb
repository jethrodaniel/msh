# frozen_string_literal: true

# mruby doesn't have squiggly here-docs
class String
  def strip_heredoc
    gsub(/^#{scan(/^[ \t]*(?=\S)/).min}/, "")
  end
end

if RUBY_ENGINE == "mruby"
  class Dir
    def self.home
      ENV["HOME"]
    end

    def self.pwd
      ENV["PWD"]
    end
  end

  module Process
    class << self
      alias wait waitpid
    end
  end

  ENV.instance_eval { alias to_h to_hash }

  module Kernel
    def exec cmd, *args
      env = {}

      if (path = ENV["PATH"]).include? ":"
        p = path.split(":").find do |p|
          f = File.join(p, cmd)
          File.file?(f) # && File.executable?(f) && !File.directory?(f)
        end
        if p
          exe = File.join(p, cmd)
          return Exec.execve(env, exe, *args)
        end
      end

      Exec.execve(env, cmd, *args)
    end
  end
end
