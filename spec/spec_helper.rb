def with_80_columns
  return yield unless $stdout.isatty

  cols = `stty -a`.split("\n")
                  .first
                  .match(/.*rows (?<rows>\d+); columns (?<columns>\d+)/)
                  .named_captures["columns"]

  `stty columns 80`
  out = yield
  `stty columns #{cols}; stty sane`
  out
end

# When we need tests that check stderr/stdout separately
#
# ```
# Output = Struct.new(:stdin, :stderr, :keyword_init => true)
# ```
def sh line
  with_80_columns do
    `#{line} 2>&1`
  end
end

require "minitest/assertions"
require "minitest/spec"

module Minitest
  module Assertions
    # Fails with a diff unless `expected` and `actual` have the same content
    #
    # Inspired by https://github.com/mint-lang/mint/blob/7634a96b39a20b2b107420d0dc2c301a31095446/spec/spec_helper.cr#L30
    def assert_equal_with_diff expected, actual
      assert expected == actual, git_diff(expected, actual)
    end

    private def git_diff expected, actual
      Dir.mktmpdir do |_dir|
        file1 = File.open("expected", "w").tap do |f|
          f.write expected
          f.close
        end
        file2 = File.open("actual", "w").tap do |f|
          f.write actual
          f.close
        end
        return `git --no-pager diff --no-index --color=always #{file1.path} #{file2.path} 2>&1`
      end
    end
  end

  module Expectations
    Enumerable.infect_an_assertion :assert_equal_with_diff, :must_equal_with_diff
  end
end

require "minitest/autorun"
