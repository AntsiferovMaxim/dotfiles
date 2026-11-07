#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

APP="$HOME/Applications/VSCodium.app"
SOURCE="$ROOT/shared/vscodium/settings.json"
CONFIG_DIR="$HOME/Library/Application Support/VSCodium/User"
TARGET="$CONFIG_DIR/settings.json"

[[ "$(uname -s)" == "Darwin" ]] || {
  echo "macOS required" >&2
  exit 1
}

[[ "$(id -u)" -ne 0 ]] || {
  echo "Do not run as root" >&2
  exit 1
}

[[ -d "$APP" ]] || {
  echo "VSCodium is not installed: $APP" >&2
  exit 1
}

[[ -f "$SOURCE" ]] || {
  echo "Missing config: $SOURCE" >&2
  exit 1
}

mkdir -p "$CONFIG_DIR"

if [[ -L "$TARGET" ]] &&
  [[ "$(readlink "$TARGET")" == "$SOURCE" ]]; then
  echo "VSCodium settings already linked."

elif [[ -e "$TARGET" || -L "$TARGET" ]]; then
  echo "Existing settings found: $TARGET" >&2
  echo "Review it before replacing." >&2
  exit 1

else
  ln -s "$SOURCE" "$TARGET"
  echo "Linked VSCodium settings."
fi

echo "VSCodium setup completed."
