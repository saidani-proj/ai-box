#!/usr/bin/env bash
# Build the opencode-notify-plugin distribution artifacts in this directory:
#   - opencode-notify-plugin-<version>.tar.gz : installation archive (tar.gz is
#                                               available on all Linux distros), with
#
#
# Usage: ./build.sh
# The curl|bash bootstrap (opencode-notify-plugin-remote-install.sh) and the download URLs live in dist/.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(dirname "$here")"

version="$(grep -m1 -oE '"version": "[0-9.]+"' "$root/src/install.sh" | grep -oE '[0-9]+\.[0-9.]+')"
[ -n "$version" ] || version="0.0.0"
archive="opencode-notify-plugin-${version}.tar.gz"

# 1) Create the installation archive directly from ../src (no staging directory needed).
tar -czf "$here/$archive" -C "$root/src" install.sh uninstall.sh notify.js

echo "built $here/$archive"
