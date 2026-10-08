#!/usr/bin/env bash
# Case:    listener.hints_forwarded
# Command: (see body)
# Expect:  repeated --hint options appear on the notify-send line
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_SEND="$TEST_DIR/bin/notify-send"
mkdir -p "$AI_BOX_NOTIF_DIR"
timeout 3 "$LISTENER" --interval 1 &
sleep 1
AI_BOX_NOTIF_DIR="$TEST_DIR/notifs" "$SHIM" --hint "a=b" --hint "c=d" "Title" "Body"
sleep 2
assert_contains "$(cat "$NS_LOG")" "--hint=a=b"
assert_contains "$(cat "$NS_LOG")" "--hint=c=d"

echo "ok: listener.hints_forwarded"
