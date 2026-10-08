#!/usr/bin/env bash
# Case:    shim.invalid_urgency_defaults_to_normal
# Command: notify-send-shim.sh -u bogus "t" "b"
# Expect:  "U=bm9ybWFs" in message file, code 0
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
out="$("$SHIM" -u bogus "t" "b" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
f=$(ls "$AI_BOX_NOTIF_DIR/out"/msg-*.msg)
assert_contains "$(cat "$f")" "$(printf '%s' normal | base64 | tr -d '\n' | sed 's/^/U=/')"

echo "ok: shim.invalid_urgency_defaults_to_normal"
