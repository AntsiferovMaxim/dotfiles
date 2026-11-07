#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

BREW="/opt/homebrew/bin/brew"
BREWFILE="$ROOT/Brewfile"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS required" >&2
  exit 1
fi

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Do not run as root" >&2
  exit 1
fi

if [[ ! -x "$BREW" ]]; then
  echo "Homebrew is not installed" >&2
  exit 1
fi

if [[ ! -f "$BREWFILE" ]]; then
  echo "Brewfile not found: $BREWFILE" >&2
  exit 1
fi

echo "=== Homebrew Packages ==="

# Refresh package metadata before checking/installing.
"$BREW" update

# Exit early if everything is already installed.
if "$BREW" bundle check --file="$BREWFILE"; then
  echo "All Brewfile packages are installed."
  exit 0
fi

echo
echo "Brewfile:"
cat "$BREWFILE"
echo

if [[ ! -t 0 ]]; then
  echo "Interactive confirmation required" >&2
  exit 1
fi

read -r -p "Install missing packages? [y/N] " answer

if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
  echo "Installation cancelled."
  exit 0
fi

"$BREW" bundle install --file="$BREWFILE"

echo "Homebrew packages installed successfully."
