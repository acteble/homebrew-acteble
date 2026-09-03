cask "acteble" do
  version "0.0.0"
  sha256 "33e44a81814f449424ef2ed1f657b83c3adb758b7d76b6b7eaa4743e141906cd" # release-bumped

  url "https://github.com/acteble/homebrew-acteble/releases/download/v#{version}/Acteble-#{version}.dmg"
  name "Acteble"
  desc "Desktop client for the Acteble platform"
  homepage "https://acteble.com/"

  auto_updates true
  depends_on macos: :big_sur

  app "Acteble.app"

  zap trash: [
    "~/Library/Application Support/com.acteble.app",
    "~/Library/Caches/com.acteble.app",
    "~/Library/Preferences/com.acteble.app.plist",
    "~/Library/Saved Application State/com.acteble.app.savedState",
  ]
end
