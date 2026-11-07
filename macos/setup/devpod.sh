#!/usr/bin/env bash
set -euo pipefail

# Configures DevPod to run dev containers on the local Docker (Colima)
# and to open them in VSCodium.

[[ "$(uname -s)" == "Darwin" ]] || {
  echo "macOS required" >&2
  exit 1
}

[[ "$(id -u)" -ne 0 ]] || {
  echo "Do not run as root" >&2
  exit 1
}

command -v devpod > /dev/null 2>&1 || {
  echo "DevPod is not installed (cask \"devpod\" in Brewfile)" >&2
  exit 1
}

command -v jq > /dev/null 2>&1 || {
  echo "Missing dependency: jq" >&2
  exit 1
}

# Do not send usage data.
devpod context set-options -o TELEMETRY=false

# Local Docker provider. It only talks to the Docker socket, so it
# works whether or not Colima is running right now.
if devpod provider list --output json | jq -e 'has("docker")' > /dev/null; then
  echo "DevPod docker provider already added."
else
  devpod provider add docker
  echo "Added DevPod docker provider."
fi

devpod provider use docker

# Open workspaces in VSCodium (Microsoft's Dev Containers extension
# is not available there; DevPod connects over SSH instead).
devpod ide use codium

echo "DevPod setup completed."
