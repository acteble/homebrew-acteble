# homebrew-acteble

Homebrew Cask tap for [Acteble](https://acteble.com)'s macOS desktop client.

```
brew tap acteble/acteble
brew install --cask acteble
```

The app's source lives in a private repo — this public tap only ships the
Cask formula (`Casks/acteble.rb`) and hosts the notarized,
Developer-ID-signed `.dmg` in its own GitHub Releases (the app's source
repo, `acteble/melos_apps`, is private, so it can't serve anonymous
downloads). Install is free; some in-app features require a purchase,
handled entirely inside the app.

## Android (internal testing)

Join the internal test track to install the Android build:

https://play.google.com/apps/internaltest/4701697952586068226

`Casks/acteble.rb`'s `version`/`sha256`/`url` are bumped automatically by
`melos_apps`' `scripts/release_homebrew.sh` after each macOS publish —
don't hand-edit them.
