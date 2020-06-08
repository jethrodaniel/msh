# frozen_string_literal: true

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

  ENV.instance_eval do
    alias to_h to_hash
  end

  module Kernel
    def exec cmd, *args
      env = ENV.to_h

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
