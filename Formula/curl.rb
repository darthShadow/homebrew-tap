#
# Homebrew Formula for curl + quiche
#
# brew install -s <url of curl.rb>
#
# You can add --HEAD if you want to build curl from git master
#
# For more information, see https://developers.cloudflare.com/http3/intro/curl-brew/
#
class Curl < Formula
  desc "Get a file from an HTTP, HTTPS or FTP server w/http3 support using quiche"
  homepage "https://curl.se"
  url "https://curl.se/download/curl-7.76.0.tar.bz2"
  sha256 "e29bfe3633701590d75b0071bbb649ee5ca4ca73f00649268bd389639531c49a"
  license "curl"

  livecheck do
    url "https://curl.se/download/"
    regex(/href=.*?curl[._-]v?(.*?)\.t/i)
  end

  head do
    url "https://github.com/curl/curl.git"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  keg_only :provided_by_macos

  depends_on "pkg-config" => :build
  depends_on "brotli"
  depends_on "libidn2"
  depends_on "libmetalink"
  depends_on "libssh2"
  depends_on "nghttp2"
  depends_on "openldap"
  depends_on "openssl@1.1"
  depends_on "rtmpdump"
  depends_on "zstd"

  uses_from_macos "krb5"
  uses_from_macos "zlib"

  # quiche
  depends_on "rust" => ["1.50.0", :build]
  depends_on "cmake" => :build

  # http2
  depends_on "nghttp2" => :build

  def install
    pwd = Pathname.pwd

    system "./buildconf" if build.head?

    # build boringssl
    system "git", "clone", "--recursive", "https://github.com/cloudflare/quiche"

    # build quiche
    cd "quiche" do
      # Build static libs only
      inreplace "Cargo.toml", /^crate-type = .*/, "crate-type = [\"staticlib\"]"

      system "cargo", "build",
                      "--release",
                      "--features", "ffi,pkg-config-meta,qlog"

      mkdir_p "deps/boringssl/src/lib"
      cp Dir.glob("target/release/build/*/out/build/libcrypto.a"), "deps/boringssl/src/lib"
      cp Dir.glob("target/release/build/*/out/build/libssl.a"), "deps/boringssl/src/lib"
    end

    args = %W[
      --disable-debug
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
      --with-secure-transport
      --without-ca-bundle
      --without-ca-path
      --with-ca-fallback
      --with-libidn2
      --with-librtmp
      --with-libssh2
      --without-libpsl
      --with-openssl=#{Formula["openssl@1.1"].opt_prefix}
      --with-openssl=#{pwd}/quiche/deps/boringssl/src
      --with-quiche=#{pwd}/quiche/target/release
      --enable-alt-svc
    ]

    on_macos do
      args << "--with-gssapi"
    end

    on_linux do
      args << "--with-gssapi=#{Formula["krb5"].opt_prefix}"
    end

    ENV.prepend "LDFLAGS", "-L#{Formula["openssl@1.1"].opt_lib}"
    ENV.prepend "CPPFLAGS", "-I#{Formula["openssl@1.1"].opt_include}"

    system "./configure", *args
    system "make", "install"
    system "make", "install", "-C", "scripts"
    libexec.install "lib/mk-ca-bundle.pl"
  end

  test do
    # Fetch the curl tarball and see that the checksum matches.
    # This requires a network connection, but so does Homebrew in general.
    filename = (testpath/"test.tar.gz")
    system "#{bin}/curl", "-L", stable.url, "-o", filename
    filename.verify_checksum stable.checksum

    system libexec/"mk-ca-bundle.pl", "test.pem"
    assert_predicate testpath/"test.pem", :exist?
    assert_predicate testpath/"certdata.txt", :exist?
  end
end
