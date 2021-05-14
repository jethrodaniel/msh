require "spec_helper"
require "msh/version"

describe Msh do
  it "has a version number" do
    _(Msh::VERSION).must_match /\d.\d.\d/
  end
end

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

    assert_screen <<~MSH
      msh v0.4.1 running on mruby v3.0 (`?` for help)
       λ repl
      Enter some ruby (sorry, no multiline). ^D to exit.
      > def prompt; "% "; end
      => :prompt
      >
      %
    MSH
  end
end
