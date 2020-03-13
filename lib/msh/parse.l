# vim: set ft=ruby:

# msh's rex lexer.
#
# Racc uses tokens like this
#
# ```
# # [:type, value]
# [:number, "3.145"]
# ```
#
# Scroll to the bottom to see usage, etc.

class Msh::Lexer
macro
  BLANK         [\ \t]+
  NEWLINE       [\n]+

  # This accepts the following:
  #
  #   - anything that's not a _special_ character
  #
  # or
  #
  #   - anything following an `\` (escape character)
  #
  # Special characters are:
  #
  #   - ` ` (space)
  #   - `;`
  #   - `&`
  #   - `|`
  #   - `<>`
  #   - `{}`
  #   - `()`
  #
  WORD          ((\\[\s;&\|<>\{\}\(\)]|[^\s\n&\|;<>\{\}\(\)])+)

rule
  {BLANK}               # no action
  \#[^\n]*[\n]*         # ignore comments until a newline
  {NEWLINE}             {
                          @line += 1
                          @column = 1
                          [:NEWLINE, text]
                        }
  time                  { [:TIME, text] }
  ;                     { [:SEMI, text] }
  \-p                   { [:TIME_OPT, text] }
  \{                    { [:LEFT_BRACE, text] }
  \}                    { [:RIGHT_BRACE, text] }
  \(                    { [:LEFT_PAREN, text] }
  \)                    { [:RIGHT_PAREN, text] }
  !                     { [:BANG, text] }
  \d+                   { [:DIGIT, text.to_i] }
  {WORD}                { [:WORD, text] }
  <>                    { [:DIAMOND, text] }
  <\&                   { [:DUP_IN, text] }
  >\&                   { [:DUP_OUT, text] }
  >>                    { [:D_REDIRECT_RIGHT, text] }
  >                     { [:REDIRECT_RIGHT, text] }
  <<                    { [:D_REDIRECT_LEFT, text] }
  <                     { [:REDIRECT_LEFT, text] }
  \|\|                  { [:OR, text] }
  \|&                   { [:PIPE_AND, text] }
  \|                    { [:PIPE, text] }
  &&                    { [:AND_AND, text] }
  &                     { [:AND, text] }
  &\>                   { [:AND_REDIRECT_RIGHT, text] }
  &\>\>                 { [:AND_D_REDIRECT_RIGHT, text] }
  \".*\"                { [:DOUBLE_QUOTE_STR, text.gsub(/^"|"$/, '')] }
  \'.*\'                { [:SINGLE_QUOTE_STR, text.gsub(/^'|'$/, '')] }

inner
  attr_reader :line, :column

  def initialize
    @line = 1
    @column = 1
  end

  def tokenize code
    scan_setup code
    tokens = []
    while token = next_token
      tokens << token
    end
    tokens
  end

  def next_token
    return if @ss.eos?

    # skips empty actions
    until token = _next_token or @ss.eos?; end

    case token
    when :NEWLINE
      @line += 1
      @column = 1
    else
      @column += token&.last&.size || 1
    end

    token
  rescue ScanError => e
    raise e
  end
end

require "msh/version"
require "msh/configuration"

# TODO: why isn't the config enough to require this?
require "optparse"

class Msh::Lexer::ScanError
  # Make rex's error message more friendly
  #
  # ```
  # --> spec/fixtures/bad/lex.sh:2:4
  #
  #  1 | fortune | cowsay -f
  #  2 | wow %
  #      ---^
  #         | cannot tokenize "%\n"
  # ```
  #
  # @param rex [Racc::Parser]
  def pretty_message rex
    token = message.delete_prefix("can not match: '").delete_suffix("'")

    # show a few lines from the file surrounding the error
    if rex.filename
      msg = "\n--> #{rex.filename}:#{rex.line}:#{rex.column}\n"

      rex.string.split("\n").each_with_index do |line, index|
        if rex.line - index + 1 <= 3
          msg += "\n  #{index + 1} | #{line}"
        end
      end

      msg += "\n      "
      (rex.column - 1).times { msg += "-" }
      msg += "^"
      msg += "\n     #{' ' * rex.column}| cannot tokenize #{token.inspect}\n"
    else
      msg = "error: cannot tokenize #{token.inspect}\n"
    end

    msg
  end
end

class Msh::Lexer
  def string
    @ss.string
  end

  def self.interactive
    while line = Readline.readline("lexer> ", true)&.chomp
      case line
      when "q", "quit", "exit"
        puts "goodbye! <3"
        exit
      else
        begin
          rex = Msh::Lexer.new
          rex.instance_eval { scan_setup line }

          while token = rex.next_token
            p token
          end
        rescue Msh::Lexer::ScanError => e
          puts e.pretty_message(rex)
        end
      end
    end
  end

  # Run the lexer on a file
  def self.lex_file filename
    rex = Msh::Lexer.new
    rex.load_file filename
    while token = rex.next_token
      p token
    end
  rescue Msh::Lexer::ScanError => e
    raise e.class.new, e.pretty_message(rex)
  end

  def self.start args = ARGV
    # Lex each file passed as input
    if args.size.positive?
      args.each do |file|
        abort "#{file} is not a file!" unless File.file?(file)

        begin
          Msh::Lexer.lex_file file
        rescue Msh::Lexer::ScanError => e
          abort e.message
        end
      end
    else
      Msh::Lexer.interactive
    end
  end
end
