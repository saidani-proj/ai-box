#!/usr/bin/env bash
# Case:    install_container.reinstall_uninstalls_first
# Command: (see body)
# Expect:  previous shim removed before reinstalling, code 0
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
mkdir -p "$AI_BOX_NOTIF_DIR/out"
"$INSTALL_CONTAINER" >/dev/null
out="$("$INSTALL_CONTAINER" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "uninstalling first"
[ -x "$HOME/.local/bin/notify-send" ] || fail "shim missing after reinstall"

echo "ok: install_container.reinstall_uninstalls_first"
