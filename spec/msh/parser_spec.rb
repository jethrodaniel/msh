# frozen_string_literal: true

RSpec.describe Msh::Parser do
  subject { Msh::Parser.new }

  Examples.passing.each do |code, data|
    it code do
      ast = eval(data[:ast], binding, __FILE__, __LINE__)
      expect(subject.parse(code)).to eq ast
    end
  end

  # Run each input and test it's output for a failure
  #
  #   "bad msh code" => [ErrorType, "error message"]
  {
    ">" => [
      Racc::ParseError,
      /\[\d\]\[\d\]: parse error on value/
      # %([1][2]: parse error on value ">" (error))
    ]
  }.each do |code, (error_class, error_msg)|
    it code.to_s do
      expect { subject.parse(code) }.to raise_error(error_class, error_msg)
    end
  end

  # **note**: testing a private method here
  describe "#expand_PIPE_AND" do
    it ":COMMAND |& :COMMAND" do
      a = s(:COMMAND, s(:WORD, "foo"))
      b = s(:COMMAND, s(:WORD, "bar"))
      p = Msh::Parser.new.send :expand_PIPE_AND, :left => a, :right => b

      expect(p).to eq \
        s(:PIPELINE,
          s(:COMMAND,
            s(:WORD, "foo"),
            s(:REDIRECTIONS,
              s(:N_DUP_OUT, 2, 1))),
          s(:COMMAND,
            s(:WORD, "bar")))
    end

    it ":COMMAND <redirections> |& :COMMAND" do
      a = s(:COMMAND, s(:WORD, "foo"), s(:REDIRECTIONS, s(:N_DUP_OUT, 3, 4)))
      b = s(:COMMAND, s(:WORD, "bar"))
      p = Msh::Parser.new.send :expand_PIPE_AND, :left => a, :right => b

      expect(p).to eq \
        s(:PIPELINE,
          s(:COMMAND,
            s(:WORD, "foo"),
            s(:REDIRECTIONS,
              s(:N_DUP_OUT, 3, 4),
              s(:N_DUP_OUT, 2, 1))), s(:COMMAND,
                                       s(:WORD, "bar")))
    end
  end
end
