#!/usr/bin/env bash
# Case:    listener.once_drains_queue
# Command: (see body)
# Expect:  per README, --once drains pending messages and delivers them, code 0
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_SEND="$TEST_DIR/bin/notify-send"
mkdir -p "$AI_BOX_NOTIF_DIR/out"
"$SHIM" "My Title" "My body"
out="$("$LISTENER" --once 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$(cat "$NS_LOG")" "My Title My body"

echo "ok: listener.once_drains_queue"
