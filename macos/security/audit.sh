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

echo "=== macOS Security Audit ==="
echo

failures=0
warnings=0

pass() {
  printf 'PASS  %s\n' "$1"
}

fail() {
  printf 'FAIL  %s\n' "$1"
  failures=$((failures + 1))
}

warn() {
  printf 'WARN  %s\n' "$1"
  warnings=$((warnings + 1))
}

# System Integrity Protection
if /usr/bin/csrutil status |
  /usr/bin/grep -q 'System Integrity Protection status: enabled'; then
  pass "System Integrity Protection enabled"
else
  fail "System Integrity Protection not fully enabled"
fi

# Gatekeeper
if /usr/sbin/spctl --status 2>&1 |
  /usr/bin/grep -q 'assessments enabled'; then
  pass "Gatekeeper enabled"
else
  fail "Gatekeeper disabled or unavailable"
fi

# FileVault
if /usr/bin/fdesetup status |
  /usr/bin/grep -q 'FileVault is On'; then
  pass "FileVault enabled"
else
  fail "FileVault not confirmed enabled"
fi

# Application Firewall
FIREWALL="/usr/libexec/ApplicationFirewall/socketfilterfw"

if [[ -x "$FIREWALL" ]]; then
  state="$("$FIREWALL" --getglobalstate 2>&1)"

  if [[ "$state" == *"enabled"* ]]; then
    pass "Application Firewall enabled"
  else
    fail "Application Firewall disabled"
  fi
else
  warn "Firewall status unavailable"
fi

# Current user privileges
if /usr/sbin/dseditgroup -o checkmember \
  -m "$(id -un)" admin 2>&1 |
  /usr/bin/grep -q 'yes'; then
  warn "Current user belongs to admin group"
else
  pass "Current user is not an administrator"
fi

# Automatic login
auto_login=$(
  /usr/bin/defaults read \
    /Library/Preferences/com.apple.loginwindow \
    autoLoginUser 2> /dev/null || true
)

if [[ -z "$auto_login" ]]; then
  pass "Automatic login not configured"
else
  fail "Automatic login configured"
fi

echo
echo "=== Persistence Inventory ==="

for dir in \
  "$HOME/Library/LaunchAgents" \
  /Library/LaunchAgents \
  /Library/LaunchDaemons; do

  echo
  echo "$dir"

  if [[ -d "$dir" ]]; then
    /usr/bin/find "$dir" \
      -maxdepth 1 \
      -type f \
      -name '*.plist' \
      -print | /usr/bin/sort
  fi
done

echo
echo "=== Persistence Check ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if bash "$SCRIPT_DIR/persistence.sh" check; then
  pass "Persistence baseline unchanged"
else
  warn "Persistence changed or check failed"
fi

echo
echo "=== Results ==="
echo "Failures: $failures"
echo "Warnings: $warnings"

if ((failures > 0)); then
  exit 1
fi

exit 0
