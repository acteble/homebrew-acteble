class Acteble < Formula
  # Prebuilt Linux x86_64 bundle (the `flutter build linux` output), published
  # to this tap's GitHub Releases alongside the macOS .dmg under the same
  # v<version> tag. Casks are macOS-only, so Linux ships as a formula that
  # installs the prebuilt bundle. The url version, version and sha256 are
  # bumped automatically by melos_apps' scripts/release_homebrew_linux.sh —
  # don't hand-edit them.
  desc "Desktop client for the Acteble platform"
  homepage "https://acteble.com"
  url "https://github.com/acteble/homebrew-acteble/releases/download/v0.0.0/acteble-linux-x86_64.tar.gz"
  version "0.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000" # release-bumped
  license :cannot_represent

  depends_on "gtk+3"
  depends_on :linux

  def install
    # The tarball root is the Flutter bundle: the `acteble` binary next to its
    # sibling lib/ and data/ dirs. Keep them together in libexec and expose the
    # binary on PATH via a symlink (Flutter resolves it back to the real path,
    # so lib/ and data/ are found next to it).
    libexec.install Dir["*"]
    bin.install_symlink libexec/"acteble"
  end

  test do
    assert_path_exists libexec/"acteble"
  end
end
