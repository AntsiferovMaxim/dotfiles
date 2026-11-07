#!/usr/bin/env bash
set -euo pipefail

if /usr/bin/xcrun --find clang > /dev/null 2>&1; then
  echo "Xcode Command Line Tools already installed"
  exit 0
fi

echo "Installing Xcode Command Line Tools..."

xcode-select --install

echo "Complete installation and rerun bootstrap."
exit 1
