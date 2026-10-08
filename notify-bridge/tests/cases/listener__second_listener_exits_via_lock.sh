#!/usr/bin/env bash
# Case:    listener.second_listener_exits_via_lock
# Command: (see body)
# Expect:  second listener exits 0 immediately when one is running
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_SEND="$TEST_DIR/bin/notify-send"
mkdir -p "$AI_BOX_NOTIF_DIR"
timeout 3 "$LISTENER" --interval 1 &
sleep 1
out="$("$LISTENER" --once 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"

echo "ok: listener.second_listener_exits_via_lock"
