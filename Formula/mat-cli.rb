class MatCli < Formula
  desc "Headless Java heap analyzer for Eclipse Memory Analyzer"
  homepage "https://github.com/Demogorgon314/mat-cli"
  version "0.1.0"
  url "https://github.com/Demogorgon314/mat-cli/releases/download/v0.1.0/mat-cli-v0.1.0.zip"
  sha256 "3be1773b6a550bcadccd67b89c1f0d9f7e1f197e18e944ca8c2b7225c7aa56c9"
  license "EPL-2.0"

  livecheck do
    url :stable
    regex(/^mat-cli-v?(\d+(?:\.\d+)+)\.zip$/i)
  end

  depends_on "openjdk@17"

  def install
    libexec.install Dir["*"]
    (bin/"mat-cli").write_env_script libexec/"mat-cli"/"mat-cli",
                                     Language::Java.overridable_java_home_env("17")
  end

  test do
    assert_match "mat-cli", shell_output("#{bin}/mat-cli --help")
  end
end
