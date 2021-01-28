require "English" unless RUBY_ENGINE == "mruby"

module Msh
  class Command
    attr_reader :name, :usage, :desc, :block

    def initialize name, usage, desc, &block
      @name = name
      @usage = usage
      @desc = desc
      @block = block
    end

    def run(...)
      block.call(...)
    end
  end

  # In msh, you're always accompanied by Ruby's `self`, which serves as context.
  #
  # Functions and aliases are just methods on this instance.
  #
  # What we want is a blank object, with no methods or anything. However, we
  # have to have a few for sanity's sake.
  class Context
    NEEDED = [
      # to see if our context can handle this, or should we call an executable?
      :respond_to?,

      # Assuming we need all of these
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

      # for creating commands
      :define_singleton_method,

      # Useful stuff
      :puts,
      :print,
      :gets,
      :loop,
      :fork,
      :exec,
      :abort,
      :warn,
      :exit!,
      :exit
    ].freeze

    HIDDEN = instance_methods - NEEDED

    HIDDEN.each { |m| undef_method m }

    def initialize
      @aliases = {}
      @commands = {}

      command :hi, "hi [NAME]", "say hi to NAME" do |name|
        puts "hello, #{name}"
      end
    end

    def command name, *args, &block
      cmd = Command.new(name, *args, &block)
      @commands[name] = cmd
      define_singleton_method cmd.name, cmd.block
      cmd
    end

    # ```
    # # `alias ls='ls --color -F'
    # alias ls ls --color -F
    # ```
    def alias cmd, *args
      @aliases[cmd.to_sym] = *args
    end

    def prompt
      # "$ "
      # "#{_ || '?'} " + Dir.pwd.gsub(ENV["HOME"], "~").green + " λ ".magenta.bold
      Dir.pwd.gsub(ENV["HOME"], "~").green + " λ ".magenta.bold
    end

    def run cmd, *args
      if alias_value = @aliases[cmd.to_sym]
        cmd, *args = *alias_value
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
          puts e.class, e.message
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
    def quit code = 0
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

    def help topic = nil
      if topic.nil?
        puts <<~HELP
          These shell commands are defined internally.
          Type `help` to see this list.
        HELP
        max_usage_len = @commands.values.max { |c| c.usage.size }.usage.size
        max_desc_len = @commands.values.max { |c| c.desc.size }.desc.size

        @commands.values.map do |cmd|
          print "\t#{cmd.usage.ljust(max_usage_len, ' ')}"
          puts "\t#{cmd.desc.ljust(max_desc_len, ' ')}"
        end
      elsif cmd = @commands[topic&.to_sym]
        puts cmd.desc
      else
        warn "no help available for command `#{topic}`."
      end
    end
    alias_method :'?', :help # rubocop:disable Style/Alias (ruby can't parse this)
  end
end
