# vim: set ft=ruby:

class Msh::Lexer
macro
  BLANK         [\ \t]+
  NEWLINE       [\n]+

  # This accepts the following:
  #
  #   - anything that's not a _special_ character
  #   - a special character preceded by a `\`
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

# [:state]  pattern  [actions]

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

            # https://www.gnu.org/software/bash/manual/html_node/Redirections.html#Redirections

            # 3.6.9 Moving File Descriptors
            #
            # move file descriptor `digit` to file descriptor `n`
            #
            #     [n]<&digit- (n defaults to 0 - stdin)
            #     [n]>&digit- (n defaults to 1 - stdout)
            #
            [\d]*<&[\d]*\-        {
                                    if text.match? /[\d]+<&[\d+]\-/
                                      [:MOVE_FD, text]
                                    else
                                      [:MOVE_FD, "0#{text}"]
                                    end
                                  }
            [\d]*>&[\d]*\-        {
                                    if text.match? /[\d]+>&[\d+]\-/
                                      [:MOVE_FD, text]
                                    else
                                      [:MOVE_FD, "1#{text}"]
                                    end
                                  }

            # 3.6.10 Opening File Descriptors for Reading and Writing
            #
            #     [n]<>word
            #
            [\d]*<>               {
                                    if text.match? /[\d]+<>/
                                      [:OPEN_RW, text]
                                    else
                                      [:OPEN_RW, "0#{text}"]
                                    end
                                  }

            # 3.6.3 Appending Redirected Output
            #
            #     [n]>>word
            #
            [\d]*>>                {
                                    if text.match?(/\d+>>/)
                                      [:APPEND, text]
                                    else
                                      [:APPEND, "1#{text}"]
                                    end
                                  }

            # 3.6.5 Appending Standard Output and Standard Error
            #
            #     &>>word
            #
            # This is semantically equivalent to
            #
            #     >>word 2>&1
            #
            &>>                   { [:APPEND_BOTH, text] }

            # 3.6.4 Redirecting Standard Output and Standard Error
            #
            #     &>word
            #     >&word
            #
            # These are semantically equivalent to
            #
            #     >word 2>&1
            #
            (&>|>&)               { [:REDIRECT_BOTH, text] }


            # 3.6.8 Duplicating File Descriptors
            #
            #     [n]<&word      duplicate input file descriptors
            #     [n]>&word      duplicate output file descriptors
            #
            # note: `word` must be a number or `-`
            #
            [\d]*<&               {
                                    if text.match? /[\d]+<&/
                                      [:DUP, text]
                                    else
                                      [:DUP, "0#{text}"]
                                    end
                                  }
            [\d]*>&               {
                                    if text.match? /[\d]+>&/
                                      [:DUP, text]
                                    else
                                      [:DUP, "1#{text}"]
                                    end
                                  }

            # 3.6.1 Redirecting Input
            #
            #     [n]<word
            #
            [\d]*<                {
                                    if text.match?(/\d+</)
                                      [:REDIRECT, text]
                                    else
                                      [:REDIRECT, "0#{text}"]
                                    end
                                  }

            # 3.6.2 Redirecting Output
            #
            #     [n]>[|]word
            #
            [\d]*>[\|]*           {
                                    if text.match?(/\d+>/)
                                      [:REDIRECT, text]
                                    elsif text.match?(/\d+>\|/)
                                      [:REDIRECT_NOCLOBBER, text]
                                    elsif text.match?(/>\|/)
                                      [:REDIRECT_NOCLOBBER, "1#{text}"]
                                    else
                                      [:REDIRECT, "1#{text}"]
                                    end
                                  }

            {WORD}                { [:WORD, text] }
            {BLANK}               # no action
            \|\|                  { [:OR, text] }
            \|&                   { [:PIPE_AND, text] }
            \|                    { [:PIPE, text] }
            &&                    { [:AND_AND, text] }
            &                     { [:AND, text] }
            &\>                   { [:AND_REDIRECT_RIGHT, text] }
            &\>\>                 { [:AND_D_REDIRECT_RIGHT, text] }
            # \".*\"                { [:DOUBLE_QUOTE_STR, text.gsub(/^"|"$/, '')] }
            # \'.*\'                { [:SINGLE_QUOTE_STR, text.gsub(/^'|'$/, '')] }

inner
  attr_reader :line, :column

  def initialize
    @line   = 1
    @column = 1
  end

  # @param code [String] input to be tokenized
  def tokenize code
    scan_setup code
    tokens = []
    while token = next_token
      tokens << token
    end
    tokens
  end
end

class Msh::Lexer
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
  #
  # @raises [Msh::Lexer::ScanError]
  def self.lex_file filename
    rex = Msh::Lexer.new
    rex.load_file filename
    while token = rex.next_token
      p token
    end
  end

  # Lex each file passed as input, or run interactively
  def self.start args = ARGV
    return Msh::Lexer.interactive if args.size.zero?

    args.each do |file|
      abort "#{file} is not a file!" unless File.file?(file)
      Msh::Lexer.lex_file file
    end
  rescue Msh::Lexer::ScanError => e
    abort e.message
  end
end
