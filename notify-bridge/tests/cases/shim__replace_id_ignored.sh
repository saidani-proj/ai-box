#!/usr/bin/env bash
# Case:    shim.replace_id_ignored
# Command: notify-send-shim.sh -r 42 "t" "b"
# Expect:  "code 0" message written
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
out="$("$SHIM" -r 42 "t" "b" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
ls "$AI_BOX_NOTIF_DIR/out"/msg-*.msg >/dev/null 2>&1 || fail "message not written"

echo "ok: shim.replace_id_ignored"
