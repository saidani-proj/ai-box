#!/usr/bin/env bash
# opencode-notify-plugin installer — run with: curl -fsSL <url>/opencode-notify-plugin-remote-install.sh | bash
set -euo pipefail

# URL of the installation archive — edit this line to point to your server.
# AI_BOX_NOTIFY_TARBALL_URL overrides it when set (useful for testing).
archive_url="${AI_BOX_NOTIFY_TARBALL_URL:-https://github.com/saidani-proj/ai-box/releases/download/v1.0.0/opencode-notify-plugin-1.0.0.tar.gz}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "downloading opencode-notify-plugin from $archive_url"
if command -v curl > /dev/null 2>&1; then
    curl -fsSL "$archive_url" -o "$tmp/opencode-notify-plugin.tar.gz"
elif command -v wget > /dev/null 2>&1; then
    wget -q "$archive_url" -O "$tmp/opencode-notify-plugin.tar.gz"
else
    echo "error: curl or wget is required" >&2
    exit 1
fi

tar -xzf "$tmp/opencode-notify-plugin.tar.gz" -C "$tmp"
"$tmp/install.sh" "$@"
