#!/usr/bin/env bash
# Case:    install_container.installs_shim
# Command: install-container.sh
# Expect:  notify-send shim and uninstaller installed
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
mkdir -p "$AI_BOX_NOTIF_DIR/out"
out="$("$INSTALL_CONTAINER" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ -x "$HOME/.local/bin/notify-send" ] || fail "shim missing"
[ -x "$HOME/.local/bin/ai-box-notify-bridge-uninstall" ] || fail "uninstaller missing"
assert_contains "$out" "installed"

echo "ok: install_container.installs_shim"
