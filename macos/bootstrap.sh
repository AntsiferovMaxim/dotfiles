#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat << EOF
Usage: $0 [--macos-defaults]

  --macos-defaults  Also apply macOS preferences (Dock, Finder,
                    trackpad, keyboard, screenshots).
EOF
}

MACOS_DEFAULTS=false

for arg in "$@"; do
  case "$arg" in
    --macos-defaults) MACOS_DEFAULTS=true ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done

echo "=== macOS Bootstrap ==="

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: macOS is required" >&2
  exit 1
fi

# Install system dependencies first.
"$ROOT/setup/xcode.sh"
"$ROOT/setup/homebrew.sh"

# Child scripts need Homebrew tools (docker, colima, jq) in PATH.
eval "$(/opt/homebrew/bin/brew shellenv)"

"$ROOT/setup/packages.sh"
"$ROOT/setup/containers.sh"
"$ROOT/setup/devpod.sh"
"$ROOT/setup/shell.sh"
"$ROOT/setup/ghostty.sh"
"$ROOT/setup/vscodium.sh"
"$ROOT/setup/starship.sh"
"$ROOT/setup/ssh.sh"
"$ROOT/setup/git.sh"

# Configure macOS preferences only when asked.
if [[ "$MACOS_DEFAULTS" == true ]]; then
  "$ROOT/config/dock.sh"
  "$ROOT/config/finder.sh"
  "$ROOT/config/trackpad.sh"
  "$ROOT/config/keyboard.sh"
  "$ROOT/config/keyboard-settings.sh"
  "$ROOT/config/screenshots.sh"
else
  echo
  echo "Skipped macOS preferences. Rerun with --macos-defaults to apply them."
fi

echo "macOS bootstrap completed"
