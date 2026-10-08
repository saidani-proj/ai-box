#!/usr/bin/env bash
# Build the ai-box distribution artifacts in this directory:
#   - ai-box-<version>.tar.gz : installation archive (tar.gz is available on all
#                               Linux distros)
#
# Usage: ./build.sh
# The curl|bash bootstrap (ai-box-remote-install.sh) and the download URL live in dist/.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(dirname "$here")"

version="$(sed -n 's/^    echo "ai-box \([0-9.]*\)"$/\1/p' "$root/src/ai-box.sh" | head -1)"
[ -n "$version" ] || version="0.0.0"
archive="ai-box-${version}.tar.gz"

# 1) Create the installation archive directly from ../src (tar.gz: tar+gzip
#    exist on every Linux distro). No staging directory needed.
tar -czf "$here/$archive" -C "$root/src" ai-box.sh install.sh uninstall.sh

echo "built $here/$archive"
