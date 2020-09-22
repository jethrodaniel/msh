require_relative "../init"

context Msh::Token do
  subject = Msh::Token.new :type   => :WORD,
                           :value  => "echo",
                           :line   => 6,
                           :column => 2

  other =
    Msh::Token.new.tap do |t|
      t.type = :WORD
      t.value = "echo"
      t.line = 6
      t.column = 2
    end

  test ".type" do
    assert(subject.type == :WORD)
  end

  test ".value" do
    assert(subject.value == "echo")
  end

  test ".line" do
    assert(subject.line == 6)
  end

  test ".column" do
    assert(subject.column == 2)
  end

  test ".to_s" do
    assert(subject.to_s == '[6:2-5][WORD, "echo"]')
  end

  test ".==" do
    assert(subject == other)
  end
end
