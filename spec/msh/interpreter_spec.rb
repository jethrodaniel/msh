# frozen_string_literal: true

RSpec.describe Msh::Interpreter do
  subject { Msh::Interpreter.new }

  # Examples.passing.take(1).each do |code, data|
  #   it code do
  #     ast = eval(data[:ast], binding, __FILE__, __LINE__)
  #     out = subject.process(ast)

  #     expect(out.existatus).to eq 1
  #   end
  # end
  it ".process" do
    ast = s(:EXPR, s(:COMMAND, s(:WORD, "fortune")))
    out = subject.process(ast)
    expect(out.exitstatus).to be_zero

    # ast = s(:EXPR, s(:COMMAND, s(:WORD, "notarealcommand")))
    # out = subject.process(ast)
    # expect(out.exitstatus).to_not be_zero
  end
end
