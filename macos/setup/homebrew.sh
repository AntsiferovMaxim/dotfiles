#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

BREW="/opt/homebrew/bin/brew"
BREW_PREFIX="/opt/homebrew"

PKG_URL="https://github.com/Homebrew/brew/releases/latest/download/Homebrew.pkg"
EXPECTED_SIGNER="Developer ID Installer: Patrick Linnane (927JGANW46)"

ZPROFILE_SOURCE="$ROOT/shared/shell/zprofile"
ZPROFILE_TARGET="$HOME/.zprofile"

log() {
  printf '\n==> %s\n' "$1"
}

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

check_environment() {
  [[ "$(uname -s)" == "Darwin" ]] ||
    fail "macOS required"

  [[ "$(uname -m)" == "arm64" ]] ||
    fail "Apple Silicon required"

  [[ "$(id -u)" -ne 0 ]] ||
    fail "Do not run as root"

  [[ -f "$ZPROFILE_SOURCE" ]] ||
    fail "Missing $ZPROFILE_SOURCE"
}

verify_package() {
  local pkg="$1"
  local signature

  log "Checking package signature"

  if ! signature="$(pkgutil --check-signature "$pkg")"; then
    fail "Invalid package signature"
  fi

  printf '%s\n' "$signature"

  if ! grep -Fq "$EXPECTED_SIGNER" <<< "$signature"; then
    fail "Unexpected package signer"
  fi

  log "Checking Gatekeeper assessment"

  if ! /usr/sbin/spctl --assess \
    --type install \
    --verbose \
    "$pkg"; then
    fail "Gatekeeper rejected the package"
  fi

  log "Package verification passed"
}

install_homebrew() {
  local temp_dir
  local pkg

  temp_dir="$(mktemp -d)"
  pkg="$temp_dir/Homebrew.pkg"

  # Remove the downloaded package when the script exits.
  # Expand temp_dir now: it is local and gone by EXIT time.
  # shellcheck disable=SC2064
  trap "rm -rf '$temp_dir'" EXIT

  log "Downloading Homebrew"

  curl \
    --fail \
    --location \
    --silent \
    --show-error \
    --proto '=https' \
    --proto-redir '=https' \
    "$PKG_URL" \
    --output "$pkg"

  verify_package "$pkg"

  log "Opening macOS Installer"

  # GUI Installer requests administrator credentials.
  # The bootstrap itself remains unprivileged.
  open -W -a Installer "$pkg"

  if [[ ! -x "$BREW" ]]; then
    fail "Homebrew installation was not completed"
  fi

  log "Homebrew installed successfully"
}

check_ownership() {
  local owner

  owner="$(stat -f '%Su' "$BREW_PREFIX")"

  if [[ "$owner" != "$(id -un)" ]]; then
    fail "Unexpected Homebrew owner: $owner (expected $(id -un))"
  fi

  log "Homebrew owner verified: $owner"
}

configure_zsh() {
  log "Configuring Zsh"

  if [[ -L "$ZPROFILE_TARGET" ]]; then
    if [[ "$(readlink "$ZPROFILE_TARGET")" == "$ZPROFILE_SOURCE" ]]; then
      echo "Zsh profile already linked"
    else
      echo "WARN: Existing symlink points elsewhere:"
      echo "  $ZPROFILE_TARGET -> $(readlink "$ZPROFILE_TARGET")"
      echo "Skipping to avoid overwriting user configuration"
    fi

  elif [[ -e "$ZPROFILE_TARGET" ]]; then
    echo "WARN: $ZPROFILE_TARGET already exists"
    echo "Skipping to avoid overwriting user configuration"

  else
    ln -s "$ZPROFILE_SOURCE" "$ZPROFILE_TARGET"
    echo "Created: $ZPROFILE_TARGET -> $ZPROFILE_SOURCE"
  fi
}

configure_homebrew() {
  log "Configuring Homebrew"

  # Disable anonymous analytics.
  "$BREW" analytics off

  # Make brew available in the current process.
  eval "$("$BREW" shellenv)"

  configure_zsh

  log "Homebrew version"
  "$BREW" --version

  log "Analytics status"
  "$BREW" analytics state
}

main() {
  check_environment

  if [[ -x "$BREW" ]]; then
    log "Homebrew already installed"
  else
    install_homebrew
  fi

  check_ownership
  configure_homebrew

  log "Homebrew setup completed"
}

main "$@"
