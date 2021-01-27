require "spec_helper"
require "msh/token"

describe Msh::Token do
  attr_accessor :subject, :other
  def setup
    @subject = Msh::Token.new :type   => :WORD,
                              :value  => "echo",
                              :line   => 6,
                              :column => 2
    @other = Msh::Token.new.tap do |t|
      t.type = :WORD
      t.value = "echo"
      t.line = 6
      t.column = 2
    end
  end

  it ".type" do
    _(subject.type).must_equal :WORD
  end

  it ".value" do
    _(subject.value).must_equal "echo"
  end

  it ".line" do
    _(subject.line).must_equal 6
  end

  it ".column" do
    _(subject.column).must_equal 2
  end

  it ".to_s" do
    _(subject.to_s).must_equal '[6:2-5][WORD, "echo"]'
  end

  it ".==" do
    _(subject).must_equal other
  end
end
