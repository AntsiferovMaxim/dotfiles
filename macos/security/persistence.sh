#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Error: macOS required" >&2
  exit 2
fi
if [[ "$(id -u)" -eq 0 ]]; then
  echo "Error: run as your regular user, without sudo" >&2
  exit 2
fi

readonly STATE_DIR="$HOME/Library/Application Support/DotfilesSecurity"
readonly BASELINE="$STATE_DIR/persistence.sha256"
readonly SCAN_DIRS=(
  "$HOME/Library/LaunchAgents"
  /Library/LaunchAgents
  /Library/LaunchDaemons
)

usage() {
  echo "Usage: $0 {snapshot|check|diff}"
}

case "${1:-}" in
  snapshot | check | diff) command_name="$1" ;;
  *)
    usage >&2
    exit 2
    ;;
esac

umask 077
workdir="$(mktemp -d "${TMPDIR:-/tmp/}persistence.XXXXXXXX")"
trap 'rm -rf "$workdir"' EXIT

scan() {
  local files="$workdir/files"
  local manifest="$workdir/current"
  local directory file hash target path kind
  : > "$files"
  : > "$manifest"

  for directory in "${SCAN_DIRS[@]}"; do
    [[ -d "$directory" ]] || continue
    # Do not silently accept an incomplete baseline when find fails.
    if ! find "$directory" \( -type f -o -type l \) -name '*.plist' -print0 >> "$files"; then
      echo "Error: cannot enumerate $directory" >&2
      return 2
    fi
  done

  while IFS= read -r -d '' file; do
    if [[ -L "$file" ]]; then
      if ! target="$(readlink "$file")"; then
        echo "Error: cannot read symlink $file" >&2
        return 2
      fi
      hash="$(printf '%s' "$target" | shasum -a 256)"
      hash="${hash%% *}"
      kind="link"
    else
      if [[ ! -r "$file" ]]; then
        echo "Error: cannot read $file" >&2
        return 2
      fi
      if ! hash="$(shasum -a 256 < "$file")"; then
        echo "Error: cannot hash $file" >&2
        return 2
      fi
      hash="${hash%% *}"
      kind="file"
    fi
    # %q escapes unusual characters, including embedded newlines.
    printf -v path '%q' "$file"
    printf '%s\t%s\t%s\n' "$path" "$kind" "$hash" >> "$manifest"
  done < "$files"

  LC_ALL=C sort -o "$manifest" "$manifest"
}

scan

if [[ "$command_name" == snapshot ]]; then
  mkdir -p "$STATE_DIR"
  chmod 700 "$STATE_DIR"
  # Stage in the same directory so mv is atomic on this filesystem.
  staged="$(mktemp "$STATE_DIR/.persistence.XXXXXXXX")"
  cp "$workdir/current" "$staged"
  chmod 600 "$staged"
  mv -f "$staged" "$BASELINE"
  echo "Saved baseline: $BASELINE"
  echo "Entries: $(wc -l < "$BASELINE" | tr -d ' ')"
  exit 0
fi

if [[ ! -f "$BASELINE" ]]; then
  echo "No baseline yet. Run: $0 snapshot" >&2
  exit 2
fi

if cmp -s "$BASELINE" "$workdir/current"; then
  echo "PASS: no LaunchAgent/LaunchDaemon plist changes detected"
  exit 0
fi

if [[ "$command_name" == check ]]; then
  echo "WARN: persistence configuration changed. Run: $0 diff" >&2
  exit 1
fi

# For changed files, print clear per-path changes.
awk -F '\t' '
  FILENAME == ARGV[1] { old[$1] = $2 FS $3; next }
  {
    seen[$1] = 1
    now = $2 FS $3
    if (!($1 in old)) print "ADDED    " $1
    else if (old[$1] != now) print "CHANGED  " $1
  }
  END {
    for (path in old) if (!(path in seen)) print "REMOVED  " path
  }
' "$BASELINE" "$workdir/current" | LC_ALL=C sort
exit 1
