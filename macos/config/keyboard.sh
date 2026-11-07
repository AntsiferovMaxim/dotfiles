#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$DIR/keyboardctl.swift"
BINARY="$DIR/.keyboardctl"

# Compile using Apple's Swift toolchain.
swiftc -framework Carbon "$SOURCE" -o "$BINARY"

# Preview changes before applying.
if [[ "${1:-}" == "--dry-run" ]]; then
  "$BINARY" apply --dry-run
else
  "$BINARY" apply
fi
