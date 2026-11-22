#!/usr/bin/env sh
set -eu

die() {
  echo "install.sh: $1" >&2
  exit 1
}

usage() {
  cat << EOF
Usage: install.sh [--help] [--dry-run]

Options:
  --help, -h    Print this help message and exit.
  --dry-run     Resolve + print what WOULD happen but do not download/modify anything.

This script installs the acteble app. To install, run:

  curl -fsSL https://raw.githubusercontent.com/acteble/homebrew-acteble/main/install.sh | sh
Installs the acteble CLI to ~/.local/bin (no sudo).
EOF
}

api_url=https://api.github.com/repos/acteble/homebrew-acteble/releases/latest
download_url=https://github.com/acteble/homebrew-acteble/releases/download
temp_dir=
mount_point=

# cleanup: runs on exit; a mounted image that cannot be detached is said.
cleanup() {
  if [ -n "$mount_point" ]; then
    hdiutil detach "$mount_point" > /dev/null || echo "install.sh: warning: could not detach $mount_point" >&2
  fi
  if [ -n "$temp_dir" ]; then
    rm -rf "$temp_dir"
  fi
}

# latest_tag: prints the tag of the latest release; dies when it cannot be
# found. It never falls back to a version it has not seen published.
latest_tag() {
  json=$(curl -fsSL "$api_url") || die "cannot fetch the latest release from $api_url"
  tag=$(printf '%s\n' "$json" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)
  [ -n "$tag" ] || die "no tag_name in the latest release"
  printf '%s\n' "$tag"
}

# fetch <tag> <asset>: downloads a release asset into the temp directory.
fetch() {
  curl -fsSL "$download_url/$1/$2" -o "$temp_dir/$2" || die "download of $2 ($1) failed"
}

prepare() {
  command -v curl > /dev/null 2>&1 || die "curl is not installed"
  temp_dir=$(mktemp -d) || die "cannot create a temporary directory"
  trap cleanup EXIT
}

install_linux() {
  [ "$arch" = x86_64 ] || die "unsupported architecture: $arch (only x86_64 Linux is supported)"
  asset=acteble-linux-x86_64.tar.gz
  target="${HOME}/.local/bin/acteble"
  if [ "$dry_run" = true ]; then
    echo "[dry-run] Would download $asset"
    echo "[dry-run] Would extract and symlink to $target"
    exit 0
  fi
  prepare
  tag=$(latest_tag)
  fetch "$tag" "$asset"
  mkdir -p "$HOME/.local/share/acteble" "$HOME/.local/bin"
  tar -xzf "$temp_dir/$asset" -C "$HOME/.local/share/acteble" || die "cannot extract $asset"
  ln -sf "$HOME/.local/share/acteble/acteble" "$target"
  echo "Installation complete. You may need to add ~/.local/bin to your PATH."
}

# install_dmg: the .dmg is named after the release tag (Acteble-<version>.dmg),
# as the Cask's url is; the app is copied from the mount point hdiutil reports.
install_dmg() {
  if [ "$dry_run" = true ]; then
    echo "[dry-run] Would download the latest Acteble-<version>.dmg"
    echo "[dry-run] Would install Acteble.app to /Applications"
    exit 0
  fi
  prepare
  tag=$(latest_tag)
  asset="Acteble-${tag#v}.dmg"
  fetch "$tag" "$asset"
  attached=$(hdiutil attach -nobrowse -readonly "$temp_dir/$asset") || die "cannot mount $asset"
  mount_point=$(printf '%s\n' "$attached" | awk -F'\t' '/\/Volumes\// { path = $NF } END { print path }')
  [ -n "$mount_point" ] || die "no mount point reported for $asset"
  [ -d "$mount_point/Acteble.app" ] || die "Acteble.app not found in $asset"
  ditto "$mount_point/Acteble.app" /Applications/Acteble.app || die "cannot copy Acteble.app to /Applications"
  echo "Installation complete: /Applications/Acteble.app"
}

install_macos() {
  if ! command -v brew > /dev/null 2>&1; then
    install_dmg
  elif [ "$dry_run" = true ]; then
    echo "[dry-run] Would run: brew install --cask acteble/acteble/acteble"
  else
    brew install --cask acteble/acteble/acteble
  fi
}

os=$(uname -s)
arch=$(uname -m)

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  usage
  exit 0
fi

dry_run=false
if [ "${1:-}" = "--dry-run" ]; then
  dry_run=true
  shift
fi

if [ -n "${1:-}" ]; then
  die "Unknown option: $1"
fi

case "$os" in
  Linux) install_linux ;;
  Darwin) install_macos ;;
  *) die "unsupported operating system: $os" ;;
esac
