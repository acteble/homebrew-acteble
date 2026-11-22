---
name: acteble-beta
description: Install, switch to or leave the beta channel of the Acteble macOS desktop client (Homebrew Cask acteble@beta of the acteble/homebrew-acteble tap). Use when the user asks for the Acteble beta, a pre-release or a test build.
---

# Acteble: beta channel

Beta exists on macOS only, as the Cask `acteble@beta`. Linux (Formula, install script), Windows and Android have no beta: the install script takes GitHub's latest release, which never includes a prerelease. Say so instead of improvising.

## What a beta is

`melos_apps/scripts/release_homebrew.sh --channel beta` publishes the build of the current branch as a GitHub **prerelease** `v<version>-beta.<build>` (build = git commit count, so each beta is newer than the last) and bumps `Casks/acteble@beta.rb`. It creates that Cask from the stable one on first use and never touches the stable Cask. As of 2026-11-22 the tap has only the stable Cask and the release `v0.0.0`: no beta has been published yet.

## First: detect what is installed

Follow the detection table of the skill `acteble`: every Homebrew channel (stable, beta, any other `acteble@<channel>`), hand-copied `/Applications/Acteble.app`, Formula, script link. Only the Casks belong to Homebrew's channels; a hand-copied app is neither and is not replaced silently: ask first.

## Check it exists

```
brew tap acteble/acteble
brew info --cask acteble/acteble/acteble@beta
```

If brew reports no such cask, no beta is published: tell the user, and offer the stable channel (skill `acteble`). Do not create the Cask by hand.

## Install

The beta Cask declares `conflicts_with cask: "acteble"`: the stable app must be removed first. Ask the user, then:

```
brew uninstall --cask acteble
brew install --cask acteble/acteble/acteble@beta
```

Update with `brew upgrade --cask acteble@beta` (the app also updates itself).

## Go back to stable

```
brew uninstall --cask acteble@beta
brew install --cask acteble
```

Both casks use the same app data under `~/Library/Application Support/com.acteble.app`: do not use `--zap` unless the user asks to delete it. A beta may write data a stable build does not read: say so before switching.
