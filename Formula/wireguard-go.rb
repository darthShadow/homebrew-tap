class WireguardGo < Formula
  desc "Tailscale fork of the Userspace Go implementation of WireGuard"
  homepage "https://www.wireguard.com/"
  license "MIT"
  head "https://github.com/Wireguard/wireguard-go.git", branch: "master"

  depends_on "go" => :build

  def install
    system "make", "PREFIX=#{prefix}", "install"
  end

  test do
    prog = "#{bin}/wireguard-go -f notrealutun 2>&1"
    if OS.mac?
      assert_match "be utun", pipe_output(prog)
    else

      assert_match "Running wireguard-go is not required because this", pipe_output(prog)
    end
  end
end
