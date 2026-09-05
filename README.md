# homebrew-acteble

Homebrew tap for [Acteble](https://acteble.com)'s desktop client (macOS and Linux).

## Quick install (curl | sh)

No Homebrew required. Installs to `~/.local/bin` (Linux) with no `sudo`:

```
curl -fsSL https://raw.githubusercontent.com/acteble/homebrew-acteble/main/install.sh | sh
```

- **Linux (x86_64):** downloads the release bundle, extracts it to
  `~/.local/share/acteble`, and symlinks `~/.local/bin/acteble`. If
  `~/.local/bin` is not on your `PATH` the installer prints the line to add.
- **macOS:** delegates to `brew install --cask acteble/acteble/acteble` when
  Homebrew is present, otherwise installs the `.dmg` to `/Applications`.

Pass `--dry-run` to preview the actions without changing anything, or `--help`
for usage.

## Windows (PowerShell)

> **Status: in preparation.** The Windows `.msix` is built by CI
> (`.github/workflows/windows-build.yml` in the app repo) and published to this
> tap's release; that build is gated on enabling GitHub Actions for the org.
> Once the first `.msix` is published, install with:
>
> ```powershell
> irm https://raw.githubusercontent.com/acteble/homebrew-acteble/main/install.ps1 | iex
> ```
>
> The `.msix` is **test-signed** (sideloadable), so Windows requires either
> Developer Mode enabled or the bundled test certificate trusted before it will
> install. `install.ps1` handles the download + `Add-AppxPackage` and explains
> the certificate step. Store distribution stays a separate Partner Center flow.

## Homebrew

macOS (Cask):

```
brew tap acteble/acteble
brew install --cask acteble
```

Linux (Formula — Casks are macOS-only, so Linux ships the prebuilt bundle
as a formula):

```
brew tap acteble/acteble
brew install acteble
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
`melos_apps`' `scripts/release_homebrew.sh` after each macOS publish, and
`Formula/acteble.rb`'s by `scripts/release_homebrew_linux.sh` after each
Linux publish — don't hand-edit either.
