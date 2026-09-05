#!/usr/bin/env sh
set -eu

die() {
  echo "install.sh: $1" >&2
  exit 1
}

usage() {
  cat << EOF
Usage: $(basename "$0") [--help] [--dry-run]

Options:
  --help, -h    Print this help message and exit.
  --dry-run     Resolve + print what WOULD happen but do not download/modify anything.

This script installs the acteble app. To install, run:

  curl -fsSL https://raw.githubusercontent.com/acteble/homebrew-acteble/main/install.sh | sh
Installs the acteble CLI to ~/.local/bin (no sudo).
EOF
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

if [ "$os" = "Linux" ]; then
  if [ "$arch" != "x86_64" ]; then
    die "unsupported architecture: $arch (only x86_64 Linux is supported)"
  fi

  asset="acteble-linux-x86_64.tar.gz"
  target="${HOME}/.local/bin/acteble"

  latest_release() {
    curl -fsSL https://api.github.com/repos/acteble/homebrew-acteble/releases/latest
  }

  download_asset() {
    tag=$(latest_release | sed -n 's/.*"tag_name":"\([^"]*\)".*/\1/p')
    if [ -z "$tag" ]; then
      echo "WARNING: Failed to fetch latest release. Falling back to v0.0.0." >&2
      tag="v0.0.0"
    fi
    url="https://github.com/acteble/homebrew-acteble/releases/download/$tag/$asset"
    curl -fsSL "$url" -o "$temp_dir/$asset"
  }

  extract_and_symlink() {
    mkdir -p "$HOME/.local/share/acteble"
    tar -xzf "$temp_dir/$asset" -C "$HOME/.local/share/acteble"
    ln -sf "$HOME/.local/share/acteble/acteble" "$target"
  }

  if [ "$dry_run" = true ]; then
    echo "[dry-run] Would download $asset"
    echo "[dry-run] Would extract and symlink to $target"
    exit 0
  fi

  temp_dir=$(mktemp -d)
  trap 'rm -rf "$temp_dir"' EXIT

  if ! command -v curl > /dev/null 2>&1; then
    die "curl is not installed"
  fi

  download_asset
  extract_and_symlink

  echo "Installation complete. You may need to add ~/.local/bin to your PATH."

elif [ "$os" = "Darwin" ]; then
  if command -v brew > /dev/null 2>&1; then
    if [ "$dry_run" = true ]; then
      echo "[dry-run] Would run: brew install --cask acteble/acteble/acteble"
      exit 0
    else
      brew install --cask acteble/acteble/acteble
    fi
  else
    asset="Acteble-0.0.0.dmg"
    latest_release() {
      curl -fsSL https://api.github.com/repos/acteble/homebrew-acteble/releases/latest
    }

    download_asset() {
      tag=$(latest_release | sed -n 's/.*"tag_name":"\([^"]*\)".*/\1/p')
      if [ -z "$tag" ]; then
        echo "WARNING: Failed to fetch latest release. Falling back to v0.0.0." >&2
        tag="v0.0.0"
      fi
      url="https://github.com/acteble/homebrew-acteble/releases/download/$tag/$asset"
      curl -fsSL "$url" -o "$temp_dir/$asset"
    }

    install_dmg() {
      hdiutil attach "$temp_dir/$asset"
      cp /Volumes/Acteble/Acteble.app /Applications
      hdiutil detach
    }

    if [ "$dry_run" = true ]; then
      echo "[dry-run] Would download $asset"
      echo "[dry-run] Would install Acteble.app to /Applications"
      exit 0
    else
      download_asset
      install_dmg
    fi
  fi

else
  die "unsupported operating system: $os"
fi
