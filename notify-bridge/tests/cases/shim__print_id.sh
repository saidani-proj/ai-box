#!/usr/bin/env bash
# Case:    shim.print_id
# Command: notify-send-shim.sh -p "t" "b"
# Expect:  prints the queue id, code 0
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
out="$("$SHIM" -p "t" "b")"; code=$?
assert_eq "$code" "0" "exit code"
assert_eq "$out" "1" "printed id"

echo "ok: shim.print_id"
