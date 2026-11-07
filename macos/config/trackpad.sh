#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS required" >&2
  exit 1
fi

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Run without sudo" >&2
  exit 1
fi

# Tap to click
for domain in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
  defaults write "$domain" Clicking -bool true
  defaults write "$domain" TrackpadRightClick -bool true
done
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Scrolling direction (also affects mice using system settings)
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true

# Force Click and haptic feedback
defaults write NSGlobalDomain com.apple.trackpad.forceClick -bool true
for domain in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
  defaults write "$domain" ForceSuppressed -bool false
  defaults write "$domain" FirstClickThreshold -int 0
done

echo "Trackpad settings applied."
echo "Log out and sign in again if changes are not visible."
