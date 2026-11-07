#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "macOS required" >&2
  exit 1
fi

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Do not run as root" >&2
  exit 1
fi

BREW="/opt/homebrew/bin/brew"
DOCKER_CONFIG="${DOCKER_CONFIG:-$HOME/.docker}"
CONFIG_FILE="$DOCKER_CONFIG/config.json"
PLUGIN_DIR="/opt/homebrew/lib/docker/cli-plugins"

for tool in "$BREW" docker colima jq; do
  command -v "$tool" > /dev/null 2>&1 || {
    if [[ ! -x "$tool" ]]; then
      echo "Missing dependency: $tool" >&2
      exit 1
    fi
  }
done

if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "Docker Compose plugin directory missing" >&2
  exit 1
fi

mkdir -p "$DOCKER_CONFIG"

if [[ -L "$CONFIG_FILE" ]]; then
  echo "Refusing to modify symlinked Docker config" >&2
  exit 1
fi

if [[ -e "$CONFIG_FILE" ]]; then
  jq -e 'type == "object"' "$CONFIG_FILE" > /dev/null
else
  printf '{}\n' > "$CONFIG_FILE"
  chmod 600 "$CONFIG_FILE"
fi

TEMP_FILE="$(mktemp "$DOCKER_CONFIG/.config.XXXXXX")"
trap 'rm -f "$TEMP_FILE"' EXIT

jq --arg dir "$PLUGIN_DIR" '
  .cliPluginsExtraDirs =
    ((.cliPluginsExtraDirs // []) + [$dir] | unique)
' "$CONFIG_FILE" > "$TEMP_FILE"

chmod 600 "$TEMP_FILE"
mv "$TEMP_FILE" "$CONFIG_FILE"

echo "Docker Compose plugin configured."
docker compose version

echo
echo "Start containers when needed:"
echo "  colima start"
echo
echo "Stop containers:"
echo "  colima stop"
