# frozen_string_literal: true

module Msh
  class Env
    # MAN
    # ```
    # ```
    def help *topics
      cmd = if topics.empty?
              %w[man msh]
            else
              %w[man] + topics.map { |t| "msh-#{t}" }
            end
      run(*cmd)
    end

    alias_method :'?', :help # rubocop:disable Style/Alias
  end
end
