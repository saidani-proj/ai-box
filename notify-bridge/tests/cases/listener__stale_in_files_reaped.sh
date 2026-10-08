#!/usr/bin/env bash
# Case:    listener.stale_in_files_reaped
# Command: (see body)
# Expect:  .in.* older than AI_BOX_NOTIF_STALE seconds removed, recent kept
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_SEND="$TEST_DIR/bin/notify-send"
export AI_BOX_NOTIF_STALE=60
mkdir -p "$AI_BOX_NOTIF_DIR"
timeout 3 "$LISTENER" --interval 1 &
sleep 1
old="$AI_BOX_NOTIF_DIR/out/.in.9991"; new="$AI_BOX_NOTIF_DIR/out/.in.9992"
: > "$old"; : > "$new"
touch -d '2 minutes ago' "$old"
sleep 2
[ ! -e "$old" ] || fail "stale .in file kept"
[ -e "$new" ] || fail "recent .in file removed"

echo "ok: listener.stale_in_files_reaped"
