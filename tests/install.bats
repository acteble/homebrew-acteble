#!/usr/bin/env bats

# Tests for install.sh. Every external command (uname, curl, tar, hdiutil,
# ditto, brew) is a stub that logs its arguments to $LOG; nothing is
# downloaded, mounted or installed.

# stub <name>: the script body is read from standard input.
stub() {
  cat > "$STUBS/$1"
  chmod +x "$STUBS/$1"
}

setup() {
  SCRIPT="${BATS_TEST_DIRNAME%/tests}/install.sh"
  STUBS="$BATS_TEST_TMPDIR/stubs"
  LOG="$BATS_TEST_TMPDIR/log"
  API="$BATS_TEST_TMPDIR/api.json"
  HOME="$BATS_TEST_TMPDIR/home"
  MOUNT="$BATS_TEST_TMPDIR/Volumes/Acteble"
  mkdir -p "$STUBS" "$HOME" "$MOUNT/Acteble.app"
  : > "$LOG"
  # The release JSON as GitHub serves it: pretty-printed, space after the colon.
  printf '{\n  "tag_name": "v1.2.3",\n  "name": "v1.2.3"\n}\n' > "$API"
  # The release list as GitHub serves it: newest first, one tag_name and one
  # prerelease flag per release.
  API_LIST="$BATS_TEST_TMPDIR/api_list.json"
  printf '[\n  {\n    "tag_name": "v2.0.0",\n    "draft": false,\n    "prerelease": false\n  },\n  {\n    "tag_name": "v2.1.0-beta.5",\n    "draft": false,\n    "prerelease": true\n  },\n  {\n    "tag_name": "v2.0.0-beta.3",\n    "draft": false,\n    "prerelease": true\n  }\n]\n' > "$API_LIST"
  export HOME LOG API API_LIST MOUNT
  export PATH="$STUBS:/usr/bin:/bin"
  stub uname << 'STUB'
#!/bin/sh
case "$1" in -s) echo "${FAKE_OS:-Linux}" ;; -m) echo "${FAKE_ARCH:-x86_64}" ;; esac
STUB
  stub curl << 'STUB'
#!/bin/sh
echo "curl $*" >> "$LOG"
[ -z "${FAKE_CURL_FAIL:-}" ] || exit 22
case "$*" in
  *api.github.com*releases?per_page*) cat "$API_LIST" ;;
  *api.github.com*) cat "$API" ;;
  *) while [ "$#" -gt 0 ]; do [ "$1" = -o ] && : > "$2"; shift; done ;;
esac
STUB
  stub tar << 'STUB'
#!/bin/sh
echo "tar $*" >> "$LOG"
[ "$3" = -C ] && touch "$4/acteble"
exit 0
STUB
  stub hdiutil << 'STUB'
#!/bin/sh
echo "hdiutil $*" >> "$LOG"
[ "$1" = attach ] && printf '/dev/disk4\tGUID\t\n/dev/disk4s1\tApple_HFS\t%s\n' "$MOUNT"
exit 0
STUB
  stub ditto << 'STUB'
#!/bin/sh
echo "ditto $*" >> "$LOG"
STUB
}

@test "linux: reads a pretty-printed tag_name and downloads that release" {
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -q "releases/download/v1.2.3/acteble-linux-x86_64.tar.gz" "$LOG"
}

@test "linux: reads a compact tag_name" {
  printf '{"tag_name":"v9.9.9"}\n' > "$API"
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -q "releases/download/v9.9.9/" "$LOG"
}

@test "linux: creates ~/.local/bin and links the binary" {
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  [ -L "$HOME/.local/bin/acteble" ]
}

@test "linux: release lookup failure stops, says so, installs nothing" {
  export FAKE_CURL_FAIL=1
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"cannot fetch the latest release"* ]]
  [ ! -e "$HOME/.local/bin/acteble" ]
}

@test "linux: a release without tag_name stops instead of using a default version" {
  printf '{"name":"x"}\n' > "$API"
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"no tag_name"* ]]
  [ "$(grep -c "releases/download" "$LOG")" -eq 0 ]
}

@test "linux: a failed download stops and installs nothing" {
  stub curl << 'STUB'
#!/bin/sh
case "$*" in *api.github.com*) cat "$API" ;; *) exit 22 ;; esac
STUB
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"download of acteble-linux-x86_64.tar.gz"* ]]
  [ ! -e "$HOME/.local/bin/acteble" ]
}

@test "linux: another architecture is refused" {
  export FAKE_ARCH=aarch64
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"unsupported architecture"* ]]
}

@test "linux: --dry-run calls nothing and changes nothing" {
  run sh "$SCRIPT" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"[dry-run]"* ]]
  [ ! -s "$LOG" ]
  [ ! -e "$HOME/.local" ]
}

@test "unknown system is refused" {
  export FAKE_OS=Plan9
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"unsupported operating system"* ]]
}

@test "unknown option is refused" {
  run sh "$SCRIPT" --nope
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unknown option"* ]]
}

@test "macos without brew: the dmg is named after the release tag" {
  export FAKE_OS=Darwin
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -q "releases/download/v1.2.3/Acteble-1.2.3.dmg" "$LOG"
}

@test "macos without brew: the app is copied from the reported mount point and the image detached" {
  export FAKE_OS=Darwin
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -q "ditto $MOUNT/Acteble.app /Applications/Acteble.app" "$LOG"
  grep -q "hdiutil detach $MOUNT" "$LOG"
}

@test "macos without brew: an image without the app fails and is still detached" {
  export FAKE_OS=Darwin
  rmdir "$MOUNT/Acteble.app"
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Acteble.app not found"* ]]
  grep -q "hdiutil detach $MOUNT" "$LOG"
  [ "$(grep -c "^ditto" "$LOG")" -eq 0 ]
}

@test "macos without brew: a failed copy fails and the image is still detached" {
  export FAKE_OS=Darwin
  stub ditto << 'STUB'
#!/bin/sh
exit 1
STUB
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"cannot copy Acteble.app"* ]]
  grep -q "hdiutil detach $MOUNT" "$LOG"
}

@test "macos without brew: a mount failure is reported" {
  export FAKE_OS=Darwin
  stub hdiutil << 'STUB'
#!/bin/sh
exit 1
STUB
  run sh "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"cannot mount"* ]]
}

@test "macos without brew: --dry-run calls nothing" {
  export FAKE_OS=Darwin
  run sh "$SCRIPT" --dry-run
  [ "$status" -eq 0 ]
  [ ! -s "$LOG" ]
}

@test "macos with brew: installs the cask through brew" {
  export FAKE_OS=Darwin
  stub brew << 'STUB'
#!/bin/sh
echo "brew $*" >> "$LOG"
STUB
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -q "brew install --cask acteble/acteble/acteble" "$LOG"
  [ "$(grep -c "^curl" "$LOG")" -eq 0 ]
}

# ---- --beta: the newest GitHub prerelease, never `releases/latest` ----

@test "beta linux: lists the releases, not just the latest one" {
  run sh "$SCRIPT" --beta
  [ "$status" -eq 0 ]
  grep -q "api.github.com/repos/acteble/homebrew-acteble/releases?per_page" "$LOG"
  ! grep -q "releases/latest" "$LOG"
}

@test "beta linux: downloads the newest prerelease, skipping a newer stable one" {
  run sh "$SCRIPT" --beta
  [ "$status" -eq 0 ]
  grep -q "releases/download/v2.1.0-beta.5/acteble-linux-x86_64.tar.gz" "$LOG"
  ! grep -q "v2.0.0/" "$LOG"
}

@test "beta linux: dies by name when no prerelease is published" {
  printf '[\n  {\n    "tag_name": "v2.0.0",\n    "prerelease": false\n  }\n]\n' > "$API_LIST"
  run sh "$SCRIPT" --beta
  [ "$status" -eq 1 ]
  [[ "$output" == *"no beta release is published"* ]] || return 1
  ! grep -q "releases/download" "$LOG"
}

@test "beta linux: a failed listing dies and installs nothing" {
  FAKE_CURL_FAIL=1 run sh "$SCRIPT" --beta
  [ "$status" -eq 1 ]
  [[ "$output" == *"cannot fetch the releases"* ]] || return 1
  [ ! -e "$HOME/.local/bin/acteble" ]
}

@test "beta: --dry-run in either order touches nothing and says beta" {
  run sh "$SCRIPT" --beta --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"[dry-run]"*"beta"* ]] || return 1
  run sh "$SCRIPT" --dry-run --beta
  [ "$status" -eq 0 ]
  [[ "$output" == *"[dry-run]"*"beta"* ]] || return 1
  [ ! -s "$LOG" ]
}

@test "beta macos with brew: installs the acteble@beta cask" {
  stub brew << 'STUB'
#!/bin/sh
echo "brew $*" >> "$LOG"
STUB
  FAKE_OS=Darwin run sh "$SCRIPT" --beta
  [ "$status" -eq 0 ]
  grep -q "brew install --cask acteble/acteble/acteble@beta" "$LOG"
}

@test "beta macos without brew: downloads the dmg of the prerelease tag" {
  FAKE_OS=Darwin run sh "$SCRIPT" --beta
  [ "$status" -eq 0 ]
  grep -q "releases/download/v2.1.0-beta.5/Acteble-2.1.0-beta.5.dmg" "$LOG"
}

@test "an unknown option still dies, beta or not" {
  run sh "$SCRIPT" --beta --nope
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown option: --nope"* ]] || return 1
}

@test "stable is unchanged: no flag still reads releases/latest" {
  run sh "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -q "releases/latest" "$LOG"
  ! grep -q "per_page" "$LOG"
}

@test "help documents --beta" {
  run sh "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"--beta"* ]] || return 1
}
