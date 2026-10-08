#!/bin/sh
# notify-bridge uninstall script (container side)
# Usage: ./uninstall-container.sh
set -eu

BIN_DIR="${AI_BOX_NOTIF_BIN:-$HOME/.local/bin}"

rm -f "$BIN_DIR/notify-send"
rm -f "$BIN_DIR/ai-box-notify-bridge-uninstall"
printf 'container shim uninstalled\n'
