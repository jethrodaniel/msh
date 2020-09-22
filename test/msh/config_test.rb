require_relative "../init"

context Msh::Config do
  test "config abilities" do
    refute Msh.config.nil?

    assert(Msh.config.color)
    assert(Msh.config.history_lines == 2_048)
    assert(Msh.config.repl == :irb)

    Msh.configure do |c|
      c.color = false
      c.history_lines = 1_000
      c.repl = :pry
    end

    refute(Msh.config.color)
    assert(Msh.config.history_lines == 1_000)
    assert(Msh.config.repl == :pry)
  end

  _test "looks for startup files" do
  end
end
