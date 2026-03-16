class MatCli < Formula
  desc "Headless Java heap analyzer for Eclipse Memory Analyzer"
  homepage "https://github.com/Demogorgon314/mat-cli"
  version "0.1.3"
  url "https://github.com/Demogorgon314/mat-cli/releases/download/v0.1.3/mat-cli-v0.1.3.zip"
  sha256 "57305cde22c2e2ec932dd227af107f23a41c92a4c64e7115ba8347a42638a203"
  license "EPL-2.0"

  livecheck do
    url :stable
    regex(/^mat-cli-v?(\d+(?:\.\d+)+)\.zip$/i)
  end

  depends_on "openjdk@17"

  def install
    libexec.install Dir["*"]
    old_cwd_snippet = <<~'SH'
      if ! CDPATH= cd -- "$DIR"; then
          echo "Unable to change directory to $DIR" >&2
          exit 1
      fi

    SH
    launcher = libexec/"mat-cli"
    inreplace launcher, old_cwd_snippet, "" if launcher.read.include?(old_cwd_snippet)
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
