#!/usr/bin/env bash
set -euo pipefail

echo "=== Security Monitoring ==="

for app in BlockBlock LuLu; do
  echo
  echo "[$app]"

  # Exact process-name match, not a substring of any command line.
  if /usr/bin/pgrep -x "$app" > /dev/null; then
    echo "PASS  Process running"
  else
    echo "WARN  No matching process found"
  fi
done

echo
echo "=== System Extensions ==="

/usr/bin/systemextensionsctl list

echo
echo "=== Background Items ==="
echo "Inspect with: sfltool dumpbtm"

echo
echo "Note: Process presence alone does not"
echo "guarantee active protection."
