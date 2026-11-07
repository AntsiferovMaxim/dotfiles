#!/usr/bin/env bash
set -euo pipefail

echo "Configuring Finder..."

# Show hidden files (including .git, .env, .config).
defaults write com.apple.finder AppleShowAllFiles -bool true

# Always show filename extensions.
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show full path in Finder window title.
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Show path bar at the bottom.
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar with item count and free space.
defaults write com.apple.finder ShowStatusBar -bool true

# Open new Finder windows in the home directory.
defaults write com.apple.finder NewWindowTarget -string "PfHm"

# Use list view by default.
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Search within the current folder by default.
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Keep folders on top when sorting by name.
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Disable warning when changing file extensions.
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

killall Finder

echo "Finder configured successfully."
