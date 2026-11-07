#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

SOURCE="$ROOT/shared/starship/starship.toml"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
TARGET="$CONFIG_DIR/starship.toml"

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Do not run as root" >&2
  exit 1
fi

if [[ ! -f "$SOURCE" ]]; then
  echo "Missing Starship config: $SOURCE" >&2
  exit 1
fi

mkdir -p "$CONFIG_DIR"

if [[ -L "$TARGET" ]] &&
  [[ "$(readlink "$TARGET")" == "$SOURCE" ]]; then
  echo "Starship config already linked."

elif [[ -e "$TARGET" || -L "$TARGET" ]]; then
  echo "Existing config found: $TARGET" >&2
  exit 1

else
  ln -s "$SOURCE" "$TARGET"
  echo "Linked Starship config."
fi

if command -v starship > /dev/null 2>&1; then
  starship explain > /dev/null
fi

echo "Starship setup completed."
