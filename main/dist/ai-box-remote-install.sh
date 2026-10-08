#!/usr/bin/env bash
# ai-box installer — run with: curl -fsSL <url>/ai-box-remote-install.sh | bash
set -euo pipefail

# URL of the installation archive — edit this line to point to your server.
# AI_BOX_TARBALL_URL overrides it when set (useful for testing).
archive_url="${AI_BOX_TARBALL_URL:-https://github.com/saidani-proj/ai-box/releases/download/v1.0.0/ai-box-1.0.0.tar.gz}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "downloading ai-box from $archive_url"
if command -v curl > /dev/null 2>&1; then
    curl -fsSL "$archive_url" -o "$tmp/ai-box.tar.gz"
elif command -v wget > /dev/null 2>&1; then
    wget -q "$archive_url" -O "$tmp/ai-box.tar.gz"
else
    echo "error: curl or wget is required" >&2
    exit 1
fi

tar -xzf "$tmp/ai-box.tar.gz" -C "$tmp"
"$tmp/install.sh" "$@"
