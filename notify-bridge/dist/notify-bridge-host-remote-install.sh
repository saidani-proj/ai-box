#!/usr/bin/env bash
# notify-bridge host installer — run with: curl -fsSL <url>/notify-bridge-host-remote-install.sh | bash
set -euo pipefail

# URL of the installation archive — edit this line to point to your server.
# AI_BOX_NOTIF_TARBALL_URL overrides it when set (useful for testing).
archive_url="${AI_BOX_NOTIF_TARBALL_URL:-https://github.com/saidani-proj/ai-box/releases/download/v1.0.0/notify-bridge-host-1.0.0.tar.gz}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "downloading notify-bridge (host) from $archive_url"
if command -v curl > /dev/null 2>&1; then
    curl -fsSL "$archive_url" -o "$tmp/notify-bridge.tar.gz"
elif command -v wget > /dev/null 2>&1; then
    wget -q "$archive_url" -O "$tmp/notify-bridge.tar.gz"
else
    echo "error: curl or wget is required" >&2
    exit 1
fi

tar -xzf "$tmp/notify-bridge.tar.gz" -C "$tmp"
"$tmp/install-host.sh"
