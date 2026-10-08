#!/bin/sh
# notify-bridge uninstall script (host side)
# Usage: ./uninstall-host.sh
set -eu

BIN_DIR="${AI_BOX_NOTIF_BIN:-$HOME/.local/bin}"
AUTOSTART_DIR="$HOME/.config/autostart"
HOST_DIR="${AI_BOX_NOTIF_DIR:-$HOME/.ai-box/notifs}"

rm -f "$BIN_DIR/ai-box-notify-bridge-listener"
rm -f "$BIN_DIR/ai-box-notify-bridge-uninstall"
rm -f "$AUTOSTART_DIR/ai-box-notify-bridge-listener.desktop"
rm -rf "$HOST_DIR"
printf 'host uninstalled\n'
