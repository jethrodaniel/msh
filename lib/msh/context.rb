 require "English" unless RUBY_ENGINE == "mruby"

module Msh
  class Context
    NEEDED = [
      # to see if our context can handle this, or should we call an executable?
      :respond_to?,

      # I assume we need these for sanity reasons?
      #
      #     BasicObject.instance_methods
      #     #=> [:__send__, :!, :==, :!=, :equal?, :__id__, :instance_eval, :instance_exec]
      #
      *BasicObject.instance_methods,

      # warning: undefining `object_id' may cause serious problems
      :object_id,

      # to check the arity of methods
      :method,

      # see what's available
      :methods,

      # `__send__` is syntactic vinegar
      :send,

      # eval is the heart and soul of msh
      :eval,
      :class_eval,

      # pry/irb/eval need these
      :is_a?,
      :to_s,
      :class,

      # Useful stuff
      :puts,
      :print,
      :gets,
      :loop,
      :fork,
      :exec,
      :abort,
      :warn,
      :exit!
    ].freeze

    HIDDEN = instance_methods - NEEDED

    HIDDEN.each { |m| undef_method m }

    def initialize
      @aliases = {}
    end

    # not really `alias` support, more like default arguments
    #
    #     alias ls --color -F # `alias ls='ls --color -F'
    #
    def alias cmd, *args
      @aliases[cmd.to_sym] = args
    end

    def hi name
      puts "hello, #{name}"
    end

    def prompt
      # "$ "
      # "#{_ || '?'} " + Dir.pwd.gsub(ENV["HOME"], "~").green + " λ ".magenta.bold
      Dir.pwd.gsub(ENV["HOME"], "~").green + " λ ".magenta.bold
    end

    def run cmd, *args
      if aliased_args = @aliases[cmd.to_sym]
        args += aliased_args
      end

      pid = fork do
        exec cmd, *args
      rescue Errno::ENOENT => e # No such file or directory
        abort e.message
      end
      Process.wait pid
      $?.exitstatus # rubocop:disable Style/SpecialGlobalVars
    end

    attr_reader :_

    # alias :$? _

    def repl
      puts "Enter some ruby (sorry, no multiline). ^D to exit."
      loop do
        print "> "
        line = gets&.chomp

        if line.nil? || line == ""
          puts ""
          return
        end

        begin
          @_ = instance_eval(line)
        rescue => e
          puts e.message
          next
        end
        puts "=> #{_.inspect}"
      end
    end

    def parser *files
      Msh::Parser.start files
      0
    end

    def lexer *files
      Msh::Lexer.start files
      0
    end

    # alias _exit exit
    def quit code = 1
      puts "goodbye! <3"
      exit! code
    end
    alias exit quit
    alias q quit

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

    def help *topics
      cmd = if topics.empty?
              %w[man msh]
            else
              %w[man] + topics.map { |t| "msh-#{t}" }
            end

      pid = fork do
        exec(*cmd)
      rescue Errno::ENOENT => e # No such file or directory
        abort e.message
      end

      Process.wait pid

      $?.exitstatus # rubocop:disable Style/SpecialGlobalVars
    end
    alias_method :'?', :help # rubocop:disable Style/Alias (ruby can't parse this)
  end
end
