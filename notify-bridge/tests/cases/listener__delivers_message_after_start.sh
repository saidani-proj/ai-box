#!/usr/bin/env bash
# Case:    listener.delivers_message_after_start
# Command: (see body)
# Expect:  message queued while listener runs is delivered to notify-send
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_SEND="$TEST_DIR/bin/notify-send"
mkdir -p "$AI_BOX_NOTIF_DIR"
timeout 3 "$LISTENER" --interval 1 &
sleep 1
"$SHIM" "T" "B"
sleep 2
assert_log_contains "T B"

echo "ok: listener.delivers_message_after_start"
