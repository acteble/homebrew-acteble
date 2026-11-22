---
name: acteble
description: Install, update or remove the stable Acteble desktop client from the acteble/homebrew-acteble tap, on macOS (Homebrew Cask), Linux x86_64 (Homebrew Formula or install script), Windows or Android. Use when the user wants Acteble, asks how to install or update it, or does not say beta.
---

# Acteble: stable channel

Source: the public tap `acteble/homebrew-acteble`. The stable channel is the latest non-prerelease GitHub Release (today `v0.0.0`). For pre-release builds see the skill `acteble-beta`.

## First: detect what is already installed

Before installing, updating or removing, find every existing install. These commands only read:

| Form | How it shows |
|---|---|
| Homebrew Cask, any channel | `brew list --cask` has `acteble` (stable) or `acteble@<channel>` (for example `acteble@beta`) |
| Homebrew Formula, any channel (Linux) | `brew list --formula` has `acteble-linux` or `acteble-linux@<channel>` |
| Install script (Linux) | `~/.local/bin/acteble` is a symlink to `~/.local/share/acteble/acteble` |
| `.dmg` copied by hand or by the script without Homebrew (macOS) | `/Applications/Acteble.app` exists but no `acteble` Cask is listed |
| Windows `.msix` | PowerShell `Get-AppxPackage *acteble*` |
| Android | not visible from a desktop: ask the user |

The Homebrew channels are not a fixed list: a channel is any Cask `acteble@<channel>` of the tap. List what the tap offers now, not what this page remembers:

```
gh api repos/acteble/homebrew-acteble/contents/Casks -q '.[].name'
gh api repos/acteble/homebrew-acteble/contents/Formula -q '.[].name'
```

A channel that is installed but no longer listed is reported as such. `command -v acteble` tells which binary wins on `PATH` when several exist. Report everything found, with its channel.

Rules once the forms are known:
- Update or remove an install through the channel it came from; never mix (no `brew uninstall` for a script install, no `rm` for a Cask).
- Stable and beta Casks conflict: they are never installed together.
- Several installs of different forms (for example the Formula and the script link on one Linux box): say so, keep all, and ask which to keep before removing any.
- A form you cannot identify is reported as unknown; do not guess its channel.

## macOS: Homebrew Cask `acteble`

```
brew tap acteble/acteble
brew install --cask acteble
```

Installs the notarized, Developer-ID-signed `.dmg` as `Acteble.app` (macOS Big Sur or newer). The app updates itself (`auto_updates true`); `brew upgrade --cask acteble` forces it. Remove: `brew uninstall --cask acteble`; `--zap` also deletes the app's data under `~/Library`: ask first.

## Linux x86_64: Homebrew Formula `acteble-linux`

```
brew tap acteble/acteble
brew install acteble-linux
```

Installs the prebuilt `flutter build linux` bundle; needs `gtk+3`. Update with `brew upgrade acteble-linux`, remove with `brew uninstall acteble-linux`.

## Any Linux or macOS: install script

It runs remote code: show the user and get their go-ahead. Preview first, nothing changes:

```
curl -fsSL https://raw.githubusercontent.com/acteble/homebrew-acteble/main/install.sh | sh -s -- --dry-run
```

Then the same command without `-s -- --dry-run`. On Linux x86_64 it extracts the latest release into `~/.local/share/acteble` and links `~/.local/bin/acteble`, no sudo. On macOS it uses the Cask when Homebrew exists, else copies the `.dmg`'s app to `/Applications`. It stops with a message when the latest release cannot be found.

## Windows

In preparation: no `.msix` is published yet, and `install.ps1` stops with `No .msix asset found on the latest acteble/homebrew-acteble release.` Say so. Once published, the `.msix` is test-signed: Windows needs Developer Mode or the bundled certificate trusted, which changes the machine's trust: ask first.

## Android

Only through the Google Play internal test track, for accounts added to it: https://play.google.com/apps/internaltest/4701697952586068226. The tap has no Android artifact; do not invent a command.

Never edit version or sha256 in the Cask or Formula by hand: `melos_apps` release scripts bump them.
