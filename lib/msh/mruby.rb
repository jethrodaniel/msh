# Extensions to make MRuby _compatible_ with CRuby

if RUBY_ENGINE == "mruby"
  $CHILD_STATUS = $? # rubocop:disable Style/SpecialGlobalVars
  $LOAD_PATH    = $: # rubocop:disable Style/SpecialGlobalVars

  module Kernel
    def puts obj
      $stdout.puts obj
    end

    def warn msg
      $stderr.puts msg # rubocop:disable Style/StderrPuts
    end

    def abort msg, exit_code = 1
      warn msg
      exit! exit_code
    end

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

    def fork &block
      Process.fork(&block)
    end
  end

  class Dir
    # mruby-dir doesn't provide this
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
end
