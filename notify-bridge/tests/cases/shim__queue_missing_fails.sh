#!/usr/bin/env bash
# Case:    shim.queue_missing_fails
# Command: (see body)
# Expect:  "queue missing", code 1
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/afile"
touch "$TEST_DIR/afile"
out="$("$SHIM" "t" "b" 2>&1)"; code=$?
[ "$code" -ne 0 ] || fail "expected non-zero exit code"
assert_contains "$out" "queue missing"

echo "ok: shim.queue_missing_fails"
