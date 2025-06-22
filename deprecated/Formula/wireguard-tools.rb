class WireguardTools < Formula
  desc "Tools for the WireGuard secure network tunnel"
  homepage "https://www.wireguard.com/"
  url "https://git.zx2c4.com/wireguard-tools/snapshot/wireguard-tools-1.0.20210914.tar.xz"
  sha256 "97ff31489217bb265b7ae850d3d0f335ab07d2652ba1feec88b734bc96bd05ac"
  license "GPL-2.0-only"
  revision 1
  head "https://github.com/darthshadow/wireguard-tools.git", branch: "master"

  livecheck do
    url :head
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "bash"
  depends_on "wireguard-go"

  def install
    if HOMEBREW_PREFIX.to_s != HOMEBREW_DEFAULT_PREFIX
      inreplace ["src/completion/wg-quick.bash-completion", "src/wg-quick/darwin.bash"],
                " /usr/local/etc/wireguard", "\\0 #{etc}/wireguard"
    end

    system "make", "-C", "src",
                         "BASHCOMPDIR=#{bash_completion}",
                         "WITH_BASHCOMPLETION=yes",
                         "WITH_WGQUICK=yes",
                         "WITH_SYSTEMDUNITS=no",
                         "PREFIX=#{prefix}",
                         "SYSCONFDIR=#{etc}",
                         "install"
  end

  test do
    system bin/"wg", "help"
  end
end
