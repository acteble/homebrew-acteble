cask "acteble" do
  version "0.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000" # bumped by scripts/release_homebrew.sh (melos_apps)

  url "https://github.com/acteble/homebrew-acteble/releases/download/v#{version}/Acteble-#{version}.dmg"
  name "Acteble"
  desc "Acteble desktop client"
  homepage "https://acteble.com"

  auto_updates true
  depends_on macos: ">= :big_sur"

  app "Acteble.app"

  zap trash: [
    "~/Library/Application Support/com.acteble.app",
    "~/Library/Caches/com.acteble.app",
    "~/Library/Preferences/com.acteble.app.plist",
    "~/Library/Saved Application State/com.acteble.app.savedState",
  ]
end
