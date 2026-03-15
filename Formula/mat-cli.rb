class MatCli < Formula
  desc "Headless Java heap analyzer for Eclipse Memory Analyzer"
  homepage "https://github.com/Demogorgon314/mat-cli"
  version "0.1.1"
  url "https://github.com/Demogorgon314/mat-cli/releases/download/v0.1.1/mat-cli-v0.1.1.zip"
  sha256 "78d494ef4442fa7e4efb965d23a1cad11b543da45585ca47ccd6ee7d1273311a"
  license "EPL-2.0"

  livecheck do
    url :stable
    regex(/^mat-cli-v?(\d+(?:\.\d+)+)\.zip$/i)
  end

  depends_on "openjdk@17"

  def install
    libexec.install Dir["*"]
    inreplace libexec/"mat-cli" do |script|
      script.sub!(<<~'SH', "")
        if ! CDPATH= cd -- "$DIR"; then
            echo "Unable to change directory to $DIR" >&2
            exit 1
        fi

      SH
    end
    (bin/"mat-cli").write_env_script libexec/"mat-cli",
                                     Language::Java.overridable_java_home_env("17")
  end

  test do
    assert_match "mat-cli", shell_output("#{bin}/mat-cli --help")

    (testpath/"query.oql").write("SELECT * FROM java.lang.String\n")
    output = shell_output("#{bin}/mat-cli oql ./missing.hprof --query-file ./query.oql 2>&1", 3)

    assert_match %r{Heap dump not found: #{Regexp.escape(testpath.to_s)}/\./missing\.hprof}, output
    refute_match %r{/libexec/}, output
  end
end
