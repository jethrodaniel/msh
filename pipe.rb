# frozen_string_literal: true

class Pipeline
  attr_reader :cmds

  Piped = Struct.new :cmd, :in, :out, :close_in, :close_out, :status, :pid do
    alias_method :close_in?, :close_in
    alias_method :close_out?, :close_out
  end

  def initialize cmds
    @cmds = cmds.map do |cmd|
      Piped.new cmd, $stdin, $stdout, false, false
    end

    @cmds.each_cons(2) do |(left, right)|
      right.in, left.out = IO.pipe
      right.close_in = true
      left.close_out = true
    end
  end

  def run
    @cmds.each do |cmd|
      cmd.pid = fork do
        $stdin.reopen  cmd.in
        $stdout.reopen cmd.out
        raise "need block" unless block_given?

        yield cmd
      end

      cmd.in.close  if cmd.close_in?
      cmd.out.close if cmd.close_out?

      Process.wait cmd.pid
      cmd.status = $?.exitstatus # rubocop:disable Style/SpecialGlobalVars
    end
  end
end

if $PROGRAM_NAME == __FILE__
  commands = [
    %w[cat],
    %w[tr a A],
    %w[tr c C]
  ]

  commands = %w[fortune rev cowsay]

  p = Pipeline.new commands
  p.run { |c| exec *c.cmd }
end
