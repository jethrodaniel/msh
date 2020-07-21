# Extensions to make MRuby _compatible_ with CRuby

$CHILD_STATUS = $? # rubocop:disable Style/SpecialGlobalVars
$LOAD_PATH = $:    # rubocop:disable Style/SpecialGlobalVars

# class Object
#   def freeze
#     self
#   end
# end

module Kernel
  def puts obj
    $stdout.puts obj
  end

  def warn msg
    $stderr.puts msg # rubocop:disable Style/StderrPuts
  end

  def abort msg
    warn msg
    exit!(1)
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

# sorry, mruby-dir, this is good enough for now
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

# load up the `lib` directory
dir = File.dirname(File.realpath(__FILE__)) # rubocop:disable Style/Dir
$LOAD_PATH << File.join(dir, "../lib")

require "msh"

def __main__ _argv
  Msh.start
end
