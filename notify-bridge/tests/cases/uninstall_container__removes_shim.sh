#!/usr/bin/env bash
# Case:    uninstall_container.removes_shim
# Command: uninstall-container.sh
# Expect:  shim and uninstaller removed
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
mkdir -p "$AI_BOX_NOTIF_DIR/out"
"$INSTALL_CONTAINER" >/dev/null
out="$("$UNINSTALL_CONTAINER" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ ! -e "$HOME/.local/bin/notify-send" ] || fail "shim still present"
[ ! -e "$HOME/.local/bin/ai-box-notify-bridge-uninstall" ] || fail "uninstaller still present"
assert_contains "$out" "uninstalled"

echo "ok: uninstall_container.removes_shim"
