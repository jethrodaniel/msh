

module Msh
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
    end

    def hi name
      puts "hello, #{name}"
    end

    def alias cmd = nil, *args
      @aliases[cmd] = *args if cmd && args.size.positive?

      raise "missing expansion for alias `#{cmd}`" if cmd && args.size.zero?

      return unless @aliases.size.positive? && args.size.zero?

      max_alias_len = @aliases.keys.sort_by(&:size).take(1).size
      @aliases.each do |a, expanded|
        puts "alias #{a.ljust(max_alias_len)} #{expanded.join(' ')}"
      end
      0
    end

    def parser *files
      Msh::Parser.start files
    end

    def lexer *files
      Msh::Lexer.start files
    end

    def prompt
      return " λ " if ENV['MSH_TEST']

      Dir.pwd.gsub(ENV["HOME"], "~").green + " λ ".magenta.bold
    end

    def run cmd, *args
      if alias_value = @aliases[cmd]
        cmd, *args = *alias_value
      end

      pid = fork do
        exec cmd, *args
      rescue Errno::ENOENT => e # No such file or directory
        abort e.message
      end
      Process.wait pid
      $?.exitstatus
    end

    attr_reader :_

    def repl
      puts "Enter some ruby (sorry, no multiline). ^D to exit."

      loop do
        # MRuby bug?
        #
        # ```
        # [2] msh/mruby/mrblib/msh.rb:356:in _call
        # [1] msh/mruby/mrblib/msh.rb:292:in repl
        # msh/third_party/mruby/mrbgems/mruby-print/mrblib/print.rb:28:in print: undefined method '__printstr__' (NoMethodError)
        # ```
        #
        Kernel.print "> "

        line = gets&.chomp

        if line.nil? || line == ""
          puts ""
          return
        end

        begin
          @_ = instance_eval(line)
        rescue => e
          puts "#{e.class}: #{e.message}"
          next
        end

        puts "=> #{_.inspect}"
      end
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
      cmd = topic.nil? ? "msh" : "msh-#{topic}"
      run "man", cmd
    end
    alias_method :'?', :help # rubocop:disable Style/Alias (ruby can't parse this)
  end
end
