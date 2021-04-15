require 'open3'
require 'tempfile'

ENV['MSH_TEST'] = 'true'

def msh str = nil
  cmd "msh #{str}" if ENV['MSH_ENGINE'] != 'ruby'
  "bundle exec bin/msh #{str}"
end

assert '`msh -V/--version` shows the version', 'CLI' do
  expected = "msh v#{Msh::VERSION} running on mruby v2.0\n"
  %w[-V --version].each do |flag|
    o, s = Open3.capture2(msh(flag))
    assert_equal o, expected
  end
end

assert '`msh -h/--help` shows usage information', 'CLI' do
  expected = <<~SH
    Usage:
        msh [options]... [file]...

    Options:
        -V, --version  show the version
        -c, --command  runs a string as shell input
        -h, --help     print this help
  SH

  %w[-h --help].each do |flag|
    o, s = Open3.capture2(msh(flag))
    assert_equal o, expected
  end
end

assert '`msh -c <cmd_string>` runs a command string', 'CLI' do
  o, s = Open3.capture2(msh('-c hi there'))
  assert_equal o, "hello, there\n"
end

assert '`msh -c` aborts when missing <cmd_string>', 'CLI' do
  o, e, s = Open3.capture3(msh('-c'))
  assert_equal o, ""
  assert_equal e, "missing argument: -c\n"
end

assert '`msh [file]...` runs [file]... as msh scripts', 'CLI' do
  script1 = Tempfile.new('1.msh')
  script1.puts "echo When in doubt,"
  script1.flush
  
  script2 = Tempfile.new('2.msh')
  script2.puts "echo Use brute force."
  script2.flush

  o, s = Open3.capture2(msh("#{script1.path} #{script2.path}"))
  assert_equal o, "When in doubt,\nUse brute force.\n"
end

assert '`msh` runs interactively', 'CLI' do
  input = <<~'MSH'
    echo π is #{Math::PI}
    echo 𝜏 is #{Math::PI * 2}
  MSH

  o, e, s = Open3.capture3(msh, :stdin_data => input)
  assert_equal o, <<~MSH.chomp
    msh v#{Msh::VERSION} running on mruby v2.0 (`?` for help)
     λ π is 3.141592653589793
     λ 𝜏 is 6.283185307179586
     λ 
  MSH
end
