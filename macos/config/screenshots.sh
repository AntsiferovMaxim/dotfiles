#!/usr/bin/env bash
set -euo pipefail

echo "Configuring screenshots..."

# Screenshot directory
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

# Save screenshots to dedicated directory
defaults write com.apple.screencapture location \
  -string "$SCREENSHOT_DIR"

# Use PNG format
defaults write com.apple.screencapture type \
  -string "png"

# Disable window shadows
defaults write com.apple.screencapture disable-shadow \
  -bool true

# Disable floating screenshot thumbnail
defaults write com.apple.screencapture show-thumbnail \
  -bool false

# Apply changes
killall SystemUIServer 2> /dev/null || true

echo "Screenshots configured successfully."
