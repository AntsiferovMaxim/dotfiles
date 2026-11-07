#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

SOURCE="$ROOT/shared/shell/zshrc"
TARGET="$HOME/.zshrc"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS required" >&2
  exit 1
fi

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Do not run as root" >&2
  exit 1
fi

if [[ ! -f "$SOURCE" ]]; then
  echo "Missing Zsh config: $SOURCE" >&2
  exit 1
fi

echo "=== Zsh Setup ==="

if [[ -L "$TARGET" ]]; then
  if [[ "$(readlink "$TARGET")" == "$SOURCE" ]]; then
    echo "Zsh configuration already linked."
  else
    echo "Existing symlink points elsewhere:"
    echo "$TARGET -> $(readlink "$TARGET")"
    exit 1
  fi
elif [[ -e "$TARGET" ]]; then
  echo "Existing $TARGET found."
  echo "Review or back it up before linking."
  exit 1
else
  ln -s "$SOURCE" "$TARGET"
  echo "Linked $TARGET -> $SOURCE"
fi

# Validate Zsh syntax.
for file in \
  "$ROOT/shared/shell/zshrc" \
  "$ROOT/shared/shell/history.zsh" \
  "$ROOT/shared/shell/completions.zsh" \
  "$ROOT/shared/shell/aliases.zsh" \
  "$ROOT/shared/shell/tools.zsh" \
  "$ROOT/shared/shell/zprofile"; do

  /bin/zsh -n "$file"
done

echo "Zsh configuration validated."
echo "Open a new terminal to apply changes."
