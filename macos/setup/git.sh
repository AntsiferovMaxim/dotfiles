#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

CONFIG="$ROOT/shared/git/gitconfig"
DELTA_CONFIG="$ROOT/shared/git/delta.gitconfig"
IGNORE_SOURCE="$ROOT/shared/git/gitignore"
HOOKS_DIR="$ROOT/shared/git/hooks"

GIT_DIR_XDG="$HOME/.config/git"
IGNORE_TARGET="$GIT_DIR_XDG/ignore"
ALLOWED_SIGNERS="$GIT_DIR_XDG/allowed_signers"
SIGNING_KEY="$HOME/.ssh/id_ed25519.pub"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

warn() {
  echo
  echo "WARN: $*"
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  fail "macOS required"
fi

if [[ "$(id -u)" -eq 0 ]]; then
  fail "Do not run as root"
fi

command -v git > /dev/null 2>&1 ||
  fail "Git is not installed"

# delta.gitconfig sets core.pager = delta.
command -v delta > /dev/null 2>&1 ||
  fail "delta is not installed (brew install git-delta)"

# The global pre-commit hook refuses to commit without gitleaks.
command -v gitleaks > /dev/null 2>&1 ||
  fail "gitleaks is not installed (brew install gitleaks)"

for file in "$CONFIG" "$DELTA_CONFIG" "$IGNORE_SOURCE" "$HOOKS_DIR/dispatch"; do
  [[ -f "$file" ]] || fail "Missing file: $file"
done

echo "=== Git Setup ==="

# Validate the configuration before installing it.
git config --file "$CONFIG" --includes --list > /dev/null ||
  fail "Invalid Git configuration"

# Register the shared configuration once.
if git config --global --get-all include.path 2> /dev/null |
  grep -Fxq "$CONFIG"; then
  echo "Git configuration already included."
else
  git config --global --add include.path "$CONFIG"
  echo "Git configuration included: $CONFIG"
fi

# Configure global gitignore.
mkdir -p "$GIT_DIR_XDG"

if [[ -L "$IGNORE_TARGET" ]] &&
  [[ "$(readlink "$IGNORE_TARGET")" == "$IGNORE_SOURCE" ]]; then
  echo "Global gitignore already linked."

elif [[ -e "$IGNORE_TARGET" || -L "$IGNORE_TARGET" ]]; then
  warn "Existing global gitignore: $IGNORE_TARGET"
  echo "Skipping to avoid overwriting it."

else
  ln -s "$IGNORE_SOURCE" "$IGNORE_TARGET"
  echo "Global gitignore linked."
fi

# Global hooks: secret scanning before every commit.
current_hooks="$(git config --global --get core.hooksPath || true)"

if [[ "$current_hooks" == "$HOOKS_DIR" ]]; then
  echo "Global Git hooks already configured."
elif [[ -n "$current_hooks" ]]; then
  warn "core.hooksPath is already set to: $current_hooks"
  echo "Skipping to avoid replacing your hooks."
else
  git config --global core.hooksPath "$HOOKS_DIR"
  echo "Global Git hooks configured: $HOOKS_DIR"
fi

# Commit signing with the SSH key. The key path is machine-specific,
# so it lives in ~/.gitconfig rather than in the shared config.
if [[ ! -f "$SIGNING_KEY" ]]; then
  warn "No SSH public key at $SIGNING_KEY."
  echo "Commits will fail until you run setup/ssh.sh and rerun this script."
elif [[ -z "$(git config --global --get user.signingKey || true)" ]]; then
  git config --global user.signingKey "$SIGNING_KEY"
  echo "Commit signing key configured: $SIGNING_KEY"
else
  echo "Commit signing key already configured."
fi

# Trust your own key when verifying signatures locally.
email="$(git config --global --get user.email || true)"

if [[ -f "$SIGNING_KEY" && -n "$email" ]]; then
  signer="$email namespaces=\"git\" $(cut -d ' ' -f 1,2 < "$SIGNING_KEY")"

  if [[ -f "$ALLOWED_SIGNERS" ]] && grep -Fxq "$signer" "$ALLOWED_SIGNERS"; then
    echo "Allowed signers already include $email."
  else
    echo "$signer" >> "$ALLOWED_SIGNERS"
    echo "Added $email to $ALLOWED_SIGNERS"
  fi
fi

echo
echo "=== Git Configuration ==="

git config --show-origin --get pull.ff
git config --show-origin --get push.default
git config --show-origin --get core.pager
git config --show-origin --get core.hooksPath || true

# user.useConfigOnly requires an explicit identity.
for key in user.name user.email; do
  if ! git config --global --get "$key" > /dev/null 2>&1; then
    warn "$key is not set. Commits will fail until you run:"
    echo "  git config --global $key \"...\""
    echo "Rerun this script afterwards to register the signing key."
  fi
done

echo
echo "Git setup completed."
