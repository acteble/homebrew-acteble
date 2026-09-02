cask "acteble" do
  version "0.0.0"
  sha256 "0dcc0fa6d0b5fa32c63d621cdfb0ab2f50d0b5c6f94ffc80bcdd7469c21331ef" # release-bumped

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
