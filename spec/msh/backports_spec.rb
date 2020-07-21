require "msh/backports"

version = RUBY_VERSION[0..2].to_f

describe "Backports" do
  if version <= 2.7
    ENV["ENV_merge_backport"] = "backports suck"
    describe ENV do
      it ".merge!" do
        expect(ENV["ENV_merge_backport"]).to eq("backports suck")
        ENV.merge! "ENV_merge_backport" => "foo"
        expect(ENV["ENV_merge_backport"]).to eq("foo")
      end
    end
  end

  if version <= 2.5
    describe String do
      it "#delete_suffix" do
        expect("abc".delete_suffix("c")).to eq("ab")
      end
    end

    describe Pathname do
      it "#glob" do
        path = Pathname.new "."
        expect(path.glob("*.c")).to eq(Dir.glob(File.join(".", "*.c")))
      end
    end
  end
end
