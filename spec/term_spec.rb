require 'rbconfig'
require 'yamatanooroti'

class MshTest < Yamatanooroti::VTermTestCase
  def setup
    start_terminal(24, 80, './bin/msh')
  end

  def test_example
    write "repl\n"
    write %(def prompt; "% "; end\n)
    write ""
    close

    ctrl_d = RbConfig::CONFIG["host_os"].include?("darwin") ? " ^D" : ""
    assert_screen <<~MSH
      msh v0.4.1 running on mruby v3.0 (`?` for help)
      $ repl
      Enter some ruby (sorry, no multiline). ^D to exit.
      > def prompt; "% "; end
      => :prompt
      >#{ctrl_d}
      %
    MSH
  end
end
