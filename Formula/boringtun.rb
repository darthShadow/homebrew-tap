class Boringtun < Formula
  desc "Userspace WireGuard implementation in Rust"
  homepage "https://github.com/cloudflare/boringtun"
  url "https://github.com/cloudflare/boringtun/archive/refs/tags/boringtun-0.5.2.tar.gz"
  sha256 "660f69e20b1980b8e75dc0373dfe137f58fb02b105d3b9d03f35e1ce299d61b3"
  license "BSD-3-Clause"
  head "https://github.com/cloudflare/boringtun.git", branch: "master"

  depends_on "rust" => :build

  def install
    system "cargo", "install", *std_cargo_args(path: "boringtun-cli")
  end

  def caveats
    <<~EOS
      boringtun requires root privileges so you will need to run `sudo boringtun utun`.
      You should be certain that you trust any software you grant root privileges.
    EOS
  end

  test do
    system "#{bin}/boringtun", "--help"
    assert_match "boringtun #{version}", shell_output("#{bin}/boringtun -V").chomp

    output = shell_output("#{bin}/boringtun utun -v --log #{testpath}/boringtun.log 2>&1", 1)
    assert_predicate testpath/"boringtun.log", :exist?
    # requires `sudo` to start
    assert_match "BoringTun failed to start", output
  end
end
