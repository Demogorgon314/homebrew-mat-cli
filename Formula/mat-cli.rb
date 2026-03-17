class MatCli < Formula
  desc "Headless Java heap analyzer for Eclipse Memory Analyzer"
  homepage "https://github.com/Demogorgon314/mat-cli"
  url "https://github.com/Demogorgon314/mat-cli/releases/download/v0.1.4/mat-cli-v0.1.4.zip"
  version "0.1.4"
  sha256 "ae859c26993769a59a3d824221dd5f31a9b38c91916367969d10be3d18235c26"
  license "EPL-2.0"

  livecheck do
    url :stable
    regex(/^mat-cli-v?(\d+(?:\.\d+)+)\.zip$/i)
  end

  depends_on "openjdk@17"

  def install
    libexec.install Dir["*"]
    old_cwd_snippet = <<~SH
      if ! CDPATH= cd -- "$DIR"; then
          echo "Unable to change directory to $DIR" >&2
          exit 1
      fi

    SH
    launcher = libexec/"mat-cli"
    inreplace launcher, old_cwd_snippet, "" if launcher.read.include?(old_cwd_snippet)
    (bin/"mat-cli").write_env_script libexec/"mat-cli",
                                     Language::Java.overridable_java_home_env("17")
    bash_completion.install libexec/"completion/bash/mat-cli"
    zsh_completion.install libexec/"completion/zsh/_mat-cli"
  end

  test do
    assert_match "mat-cli", shell_output("#{bin}/mat-cli --help")
    (testpath/"query.oql").write("SELECT * FROM java.lang.String\n")
    output = shell_output("#{bin}/mat-cli oql ./missing.hprof --query-file ./query.oql 2>&1", 3)

    assert_match %r{Heap dump not found: #{Regexp.escape(testpath.to_s)}/\./missing\.hprof}, output
    refute_match %r{/libexec/}, output
    assert_path_exists bash_completion/"mat-cli"
    assert_path_exists zsh_completion/"_mat-cli"
  end
end
