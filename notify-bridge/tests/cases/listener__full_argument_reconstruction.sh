#!/usr/bin/env bash
# Case:    listener.full_argument_reconstruction
# Command: (see body)
# Expect:  reconstructed -a/-i/-u/-t line passed to host notify-send
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_SEND="$TEST_DIR/bin/notify-send"
mkdir -p "$AI_BOX_NOTIF_DIR"
timeout 3 "$LISTENER" --interval 1 &
sleep 1
AI_BOX_NOTIF_DIR="$TEST_DIR/notifs" "$SHIM" -u critical -a MyApp -i myicon -t 5000 "Title" "Body"
sleep 2
assert_contains "$(cat "$NS_LOG")" "-a MyApp -i myicon -u critical -t 5000 Title Body"

echo "ok: listener.full_argument_reconstruction"
