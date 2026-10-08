#!/usr/bin/env bash
# Case:    listener.rejects_shim_as_send
# Command: (see body)
# Expect:  "shim", code 1
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_SEND="$SHIM"
out="$("$LISTENER" --once 2>&1)"; code=$?
[ "$code" -ne 0 ] || fail "expected non-zero exit code"
assert_contains "$out" "shim"

echo "ok: listener.rejects_shim_as_send"
