#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

SOURCE="$ROOT/shared/ssh/config"
SSH_DIR="$HOME/.ssh"
CONFIG="$SSH_DIR/config"
KEY="$SSH_DIR/id_ed25519"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

[[ "$(uname -s)" == "Darwin" ]] || fail "macOS required"
[[ "$(id -u)" -ne 0 ]] || fail "Do not run as root"
[[ -f "$SOURCE" ]] || fail "Missing SSH config: $SOURCE"

echo "=== SSH Setup ==="

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Include the shared config at the end of ~/.ssh/config.
# "Match all" closes any preceding Host/Match block, so the
# Include is always processed instead of only for that host.
if [[ -L "$CONFIG" ]]; then
  fail "Refusing to modify symlinked $CONFIG"
fi

touch "$CONFIG"
chmod 600 "$CONFIG"

if grep -Fxq "Include $SOURCE" "$CONFIG"; then
  echo "Shared SSH config already included."
else
  # Terminate the last line if the file lacks a trailing newline.
  if [[ -s "$CONFIG" && -n "$(tail -c 1 "$CONFIG")" ]]; then
    echo >> "$CONFIG"
  fi

  {
    echo
    echo "# Shared defaults from dotfiles (keep at the end of this file)."
    echo "Match all"
    echo "Include $SOURCE"
  } >> "$CONFIG"
  echo "Shared SSH config included in $CONFIG"
fi

# Validate the resulting configuration.
ssh -T -G github.com < /dev/null > /dev/null || fail "Invalid SSH configuration"

# Create a key only if none exists. Never overwrite keys.
if [[ -f "$KEY" ]]; then
  echo "SSH key exists: $KEY"
elif [[ ! -t 0 ]]; then
  echo "WARN: No SSH key and no terminal; skipping key creation."
else
  read -r -p "No SSH key found. Create $KEY? [Y/n] " answer

  if [[ "$answer" != "n" && "$answer" != "N" ]]; then
    # -a 100: stronger passphrase KDF. ssh-keygen asks for the passphrase.
    ssh-keygen -t ed25519 -a 100 \
      -C "$(id -un)@$(scutil --get LocalHostName)" \
      -f "$KEY"

    # Store the passphrase in the login Keychain and load the key,
    # so Git commit signing works without an SSH connection first.
    ssh-add --apple-use-keychain "$KEY"
  fi
fi

if [[ -f "$KEY.pub" ]]; then
  echo
  echo "Public key:"
  cat "$KEY.pub"
  echo
  echo "Add it to GitHub for authentication and commit signing:"
  echo "  gh ssh-key add $KEY.pub --type authentication --title \"$(scutil --get LocalHostName)\""
  echo "  gh ssh-key add $KEY.pub --type signing --title \"$(scutil --get LocalHostName)\""
fi

echo
echo "SSH setup completed."
