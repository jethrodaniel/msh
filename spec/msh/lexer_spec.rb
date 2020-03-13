# frozen_string_literal: true

# LEX_DATA = {
#  "git c -m 'update readme'" => [
#    [:WORD, "git"],
#    [:WORD, "c"],
#    [:WORD, "-m"],
#    [:SINGLE_QUOTE_STR, "update readme"]
#  ],
#  'echo "#{Time.now}"' => [
#    [:WORD, "echo"],
#    [:DOUBLE_QUOTE_STR, '#{Time.now}']
#  ],

#  #
#  # globs, wildcards, etc
#  #
#  "ls *.c" => [
#    [:WORD, "ls"],
#    [:GLOB, "*"],
#    [:WORD, ".c"]
#  ],
#  "ls foo.?" => [
#    [:WORD, "ls"],
#    [:WORD, "foo."],
#    [:QUESTION, "?"]
#  ],

#  #
#  # newlines, continuation, etc
#  #
#  "\n" => [
#    [:NEWLINE, "\n"]
#  ],

#  #
#  # redirection
#  #
#  "tail file > tail.log" => [
#    [:WORD, "tail"],
#    [:WORD, "file"],
#    [:REDIRECT_RIGHT, ">"],
#    [:WORD, "tail.log"]
#  ],
#  "tail -n100 log >> tail.log" => [
#    [:WORD, "tail"],
#    [:WORD, "-n100"],
#    [:WORD, "log"],
#    [:DOUBLE_REDIRECT_RIGHT, ">>"],
#    [:WORD, "tail.log"]
#  ],
#  "psql -Uuser -d db< file.sql" => [
#    [:WORD, "psql"],
#    [:WORD, "-Uuser"],
#    [:WORD, "-d"],
#    [:WORD, "db"],
#    [:REDIRECT_LEFT, "<"],
#    [:WORD, "file.sql"]
#  ],
#  "a 1> 2>&1 3<&2 3>out" => [
#    [:WORD, "a"],
#    [:REDIRECT_RIGHT, "1>"],
#    [:REDIRECT_INTO, "2>&1"],
#    [:REDIRECT_FROM, "3<&2"],
#    [:REDIRECT_RIGHT, "3>"],
#    [:WORD, "out"]
#  ],
#  "foo <input >output" => [
#    [:WORD, "foo"],
#    [:REDIRECT_LEFT, "<"],
#    [:WORD, "input"],
#    [:REDIRECT_RIGHT, ">"],
#    [:WORD, "output"]
#  ]

# }.freeze

# RSpec.describe Msh::Lexer do
#   subject { Msh::Lexer.new }

#   LEX_DATA.each do |code, tokens|
#     it code.to_s do
#       expect(subject.tokenize(code)).to eq tokens
#     end
#   end
# end

RSpec.describe Msh::Lexer do
  subject { Msh::Lexer.new }

  let(:ruby_version) { RUBY_VERSION.gsub(/[^\d]/, "")[0..2].to_i * 0.01 }

  Examples.passing.each do |code, data|
    it code do
      tokens = if ruby_version < 2.6
                 binding.eval(data[:tokens], __FILE__, __LINE__)
               else
                 binding.eval(data[:tokens], *binding.source_location)
               end

      expect(subject.tokenize(code)).to eq tokens
    end
  end
end
