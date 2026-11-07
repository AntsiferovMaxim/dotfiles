#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script requires macOS" >&2
  exit 1
fi

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Run as your regular user, without sudo" >&2
  exit 1
fi

# Keyboard repeat
# Values are in approximately 15 ms units.
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Hold a key to repeat instead of showing the accents popup.
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Text input: disable automatic substitutions.
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Allow Tab navigation across controls.
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

echo "Keyboard settings applied. Log out and back in to apply all changes."
