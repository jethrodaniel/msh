require "spec_helper"

def msh cmd
  sh "bundle exec bin/msh -c '#{cmd}'"
end

describe "msh builtins" do
  describe "alias" do
    it "shows all aliases when ran without args" do
     skip "alias"
      _(msh("alias")).must_equal <<~SH
        alias ls ls -lrth --color
      SH
    end
    it "errors if an alias name is present, but no args" do
     skip "alias"
      _(msh("alias foo")).must_include <<~SH
        missing expansion for alias `foo` (RuntimeError)
      SH
    end
    it "creates an alias for a series of words" do
     skip "alias"
      _(msh("alias foo bar; foo")).must_include <<~SH
        No such file or directory - bar
      SH
    end
  end
end
