#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

APP="$HOME/Applications/Ghostty.app"
SOURCE="$ROOT/shared/ghostty/config.ghostty"
CONFIG_DIR="$HOME/.config/ghostty"
TARGET="$CONFIG_DIR/config.ghostty"

[[ "$(uname -s)" == "Darwin" ]] || {
  echo "macOS required" >&2
  exit 1
}

[[ "$(id -u)" -ne 0 ]] || {
  echo "Do not run as root" >&2
  exit 1
}

[[ -d "$APP" ]] || {
  echo "Ghostty is not installed: $APP" >&2
  exit 1
}

[[ -f "$SOURCE" ]] || {
  echo "Missing config: $SOURCE" >&2
  exit 1
}

mkdir -p "$CONFIG_DIR"

if [[ -L "$TARGET" ]] &&
  [[ "$(readlink "$TARGET")" == "$SOURCE" ]]; then
  echo "Ghostty config already linked."

elif [[ -e "$TARGET" || -L "$TARGET" ]]; then
  echo "Existing config found: $TARGET" >&2
  echo "Review it before replacing." >&2
  exit 1

else
  ln -s "$SOURCE" "$TARGET"
  echo "Linked Ghostty config."
fi

# Check for macOS-specific overrides.
MAC_CONFIG="$HOME/Library/Application Support/com.mitchellh.ghostty"

if [[ -f "$MAC_CONFIG/config.ghostty" ||
  -f "$MAC_CONFIG/config" ]]; then
  echo "WARN: macOS-specific Ghostty config exists."
  echo "It may override settings from ~/.config/ghostty."
fi

# Validate the installed Ghostty configuration.
GHOSTTY="$APP/Contents/MacOS/ghostty"

if [[ -x "$GHOSTTY" ]]; then
  "$GHOSTTY" +validate-config
fi

echo "Ghostty setup completed."
