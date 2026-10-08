#!/usr/bin/env bash
# Case:    listener.missing_send_binary
# Command: (see body)
# Expect:  "notify-send not found in PATH", code 1
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_SEND=definitely-not-a-real-binary
out="$("$LISTENER" --once 2>&1)"; code=$?
[ "$code" -ne 0 ] || fail "expected non-zero exit code"
assert_contains "$out" "notify-send not found in PATH"

echo "ok: listener.missing_send_binary"
