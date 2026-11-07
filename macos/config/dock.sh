#!/usr/bin/env bash
set -euo pipefail

# Remove all pinned applications.
# Finder and Trash remain available.
defaults write com.apple.dock persistent-apps -array

# Remove folders and stacks, including Downloads.
defaults write com.apple.dock persistent-others -array

# Hide recently used applications.
defaults write com.apple.dock show-recents -bool false

# Set Dock icon size to 32 pixels.
defaults write com.apple.dock tilesize -int 32
defaults write com.apple.dock autohide -bool true

# Disable icon magnification.
defaults write com.apple.dock magnification -bool false

# Keep running applications visible when opened.
defaults write com.apple.dock static-only -bool false

# Position Dock at the bottom.
defaults write com.apple.dock orientation -string bottom

# Apply changes.
killall Dock

echo "Dock configured successfully."
