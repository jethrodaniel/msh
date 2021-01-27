require "spec_helper"
require "msh/backports"

version = RUBY_VERSION[0..2].to_f

describe "Backports" do
  if version <= 2.7
    ENV["ENV_merge_backport"] = "backports suck"
    describe ENV do
      it ".merge!" do
        _(ENV["ENV_merge_backport"]).must_equal "backports suck"
        ENV.merge! "ENV_merge_backport" => "foo"
        _(ENV["ENV_merge_backport"]).must_equal "foo"
      end
    end
  end

  if version <= 2.5
    describe String do
      it "#delete_suffix" do
        _("abc".delete_suffix("c")).must_equal "ab"
      end
    end

    describe Pathname do
      it "#glob" do
        path = Pathname.new "."
        _(path.glob("*.c")).must_equal Dir.glob(File.join(".", "*.c"))
      end
    end
  end
end
