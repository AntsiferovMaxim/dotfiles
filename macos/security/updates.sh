#!/usr/bin/env bash
set -euo pipefail

echo "=== macOS Update Settings ==="

DOMAIN="/Library/Preferences/com.apple.SoftwareUpdate"

for key in \
  AutomaticCheckEnabled \
  AutomaticDownload \
  AutomaticallyInstallMacOSUpdates \
  CriticalUpdateInstall \
  ConfigDataInstall; do

  value="$(defaults read "$DOMAIN" "$key" 2> /dev/null || true)"
  printf '%-36s %s\n' "$key" "${value:-not set}"
done

echo
echo "Available updates:"
softwareupdate --list
