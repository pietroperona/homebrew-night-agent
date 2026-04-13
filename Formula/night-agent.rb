class NightAgent < Formula
  desc "Runtime security layer for AI agents on macOS"
  homepage "https://github.com/pietroperona/night-agent"
  url "https://github.com/pietroperona/night-agent/archive/refs/tags/v0.3.0.tar.gz"
  sha256 "3ea06ac959fbb39df499e85e7d29748ccc877fc43df3ad0c85b63daa88901865"
  license "MIT"
  head "https://github.com/pietroperona/night-agent.git", branch: "main"

  depends_on "go" => :build
  depends_on :macos

  def install
    # Compila il binario principale Go
    system "go", "build", "-o", bin/"nightagent", "./cmd/guardian"

    # Compila shim C nella dir corrente, poi installa (libexec.install crea la dir)
    system "clang", "-o", "guardian-shim",
           "internal/shim/csrc/guardian_shim.c",
           "-Wall", "-Wextra", "-Wno-unused-parameter"
    libexec.install "guardian-shim"
    (libexec/"shims").mkpath

    # Compila dylib nella dir corrente, poi installa
    system "clang", "-dynamiclib",
           "-o", "guardian-intercept.dylib",
           "internal/intercept/csrc/guardian_intercept.c",
           "-Wall", "-Wextra", "-Wno-unused-parameter",
           "-current_version", "1.0",
           "-compatibility_version", "1.0"
    lib.install "guardian-intercept.dylib"

    # Installa la policy di default
    pkgshare.install "configs"
  end

  def post_install
    guardian_dir = Pathname.new(ENV["HOME"]) / ".night-agent"
    policy_dest = guardian_dir / "policy.yaml"
    policy_src = pkgshare / "configs" / "default_policy.yaml"

    unless policy_dest.exist?
      guardian_dir.mkpath
      FileUtils.cp policy_src, policy_dest
      policy_dest.chmod(0600)
    end
  end

  def caveats
    <<~EOS
      Night Agent installato. Per completare la configurazione:

        nightagent init

      Per le funzionalità sandbox installa Docker Desktop:
        https://www.docker.com/products/docker-desktop/

      Per verificare che tutto funzioni:
        nightagent doctor
    EOS
  end

  test do
    output = shell_output("#{bin}/nightagent --help")
    assert_match "nightagent", output
    assert_predicate pkgshare / "configs" / "default_policy.yaml", :exist?
  end
end
