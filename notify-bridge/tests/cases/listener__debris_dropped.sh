#!/usr/bin/env bash
# Case:    listener.debris_dropped
# Command: (see body)
# Expect:  malformed files are removed by the listener
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_SEND="$TEST_DIR/bin/notify-send"
mkdir -p "$AI_BOX_NOTIF_DIR"
timeout 3 "$LISTENER" --interval 1 &
sleep 1
echo "garbage" > "$AI_BOX_NOTIF_DIR/out/msg-000000000099.msg"
sleep 2
[ ! -e "$AI_BOX_NOTIF_DIR/out/msg-000000000099.msg" ] || fail "debris not removed"

echo "ok: listener.debris_dropped"
