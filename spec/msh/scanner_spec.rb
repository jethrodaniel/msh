# frozen_string_literal: true

require "msh/scanner"

describe Msh::Scanner do
  subject { Msh::Scanner.new "abc" }

  it "maintains a pointer to a index in a string" do
    expect(subject.current_char).to eq "a"
    expect(subject.pos).to eq 0
    expect(subject.advance).to eq "a"

    expect(subject.current_char).to eq "b"
    expect(subject.pos).to eq 1
    expect(subject.advance).to eq "b"

    expect(subject.current_char).to eq "c"
    expect(subject.pos).to eq 2
    expect(subject.advance).to eq "c"

    expect(subject.current_char).to eq "\x0"
    expect(subject.pos).to eq 3
    expect(subject.advance).to eq "\x0"

    expect(subject.pos).to eq 4
  end

  it "#peek" do
    expect(subject.peek).to eq "b"
    expect(subject.peek(1)).to eq "b"
    expect(subject.peek(2)).to eq "bc"
    expect(subject.peek(3)).to eq "bc"
    expect(subject.peek(4)).to eq "bc"
  end

  it "#eof?" do
    expect(subject.eof?).to be false
    subject.advance
    expect(subject.eof?).to be false
    subject.advance
    expect(subject.eof?).to be false
    subject.advance
    expect(subject.eof?).to be true
    subject.advance
    expect(subject.eof?).to be true
    expect(subject.current_char).to eq "\x0"
    subject.advance
    expect(subject.current_char).to eq "\x0"
  end

  it "#backup" do
    3.times { subject.advance }
    3.times { subject.backup }
    expect(subject.current_char).to eq "a"
  end

  it "#reset" do
    3.times { subject.advance }
    subject.reset 0
    expect(subject.current_char).to eq "a"

    subject.reset 2
    expect(subject.current_char).to eq "c"

    expect { subject.reset 3 }.to raise_error(RuntimeError, "pos (3) exceeds source length (3)")

    subject.reset 1
    expect(subject.current_char).to eq "b"

    expect { subject.reset -3 }.to raise_error(RuntimeError, "pos is less than zero (-3)")
  end

  it "#line, #column" do
    subject = Msh::Scanner.new <<~CODE
      echo wow
      would you
      look at
      that\n
      !
    CODE

    expect_pos = -> line, column do
      expect(subject.line).to eq line
      expect(subject.column).to eq column
    end

    expect_pos.(1, 1)
    subject.advance
    expect_pos.(1, 2)
    7.times { subject.advance }
    expect_pos.(1, 9)
    subject.advance
    expect_pos.(2, 1)
    12.times { subject.advance }
    expect_pos.(3, 3)

    # subject.reset 0
    # expect_pos.(1, 1)
  end
end
