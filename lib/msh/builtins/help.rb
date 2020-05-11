# frozen_string_literal: true

module Msh
  class Env
    # == name
    #
    # help - msh man pages
    #
    # == synopsis
    #
    # *help* [_topic_]...
    #
    # == description
    #
    # Msh's _help_ builtin is just a wrapper around the _man_ command, such
    # that topics are prefixed with _msh-_.
    #
    #     msh> help help   #=> same as `man msh-help`
    #     msh> help        #=> same as `man msh`
    #     msh> help wtf    #=> No manual entry for msh-wtf
    #
    # Msh modifies your $MANPATH so these are available. To install them
    # outside of msh, either add msh's man directory to your $MANPATH, or
    # install it's manpages on your system the traditional way.
    #
    #     MANPATH=<path to msh man/man1 dir> man msh
    #
    #     msh_manpath="$(dirname $(gem which msh))/../man/man1/"
    #     cp -r $msh_manpath /usr/local/share/man/man1/
    #     mandb
    #     man msh
    #
    def help *topics
      cmd = if topics.empty?
              %w[man msh]
            else
              %w[man] + topics.map { |t| "msh-#{t}" }
            end

      pid = fork do
        begin
          exec *cmd
        rescue Errno::ENOENT => e # No such file or directory
          abort e.message
        end
      end

      Process.wait pid

      $CHILD_STATUS.exitstatus
    end

    alias_method :'?', :help # rubocop:disable Style/Alias (ruby can't parse this)
  end
end
