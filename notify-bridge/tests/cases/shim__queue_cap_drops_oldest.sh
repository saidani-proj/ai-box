#!/usr/bin/env bash
# Case:    shim.queue_cap_drops_oldest
# Command: (see body)
# Expect:  at most AI_BOX_NOTIF_MAX files, newest kept, verbose warns
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_MAX=3 AI_BOX_NOTIF_VERBOSE=1
for i in 1 2 3 4 5; do "$SHIM" "m$i" "b$i" 2>>"$TEST_DIR/verbose.log"; done
[ "$(ls "$AI_BOX_NOTIF_DIR/out"/msg-*.msg | wc -l)" = "3" ] || fail "expected 3 messages kept"
ls "$AI_BOX_NOTIF_DIR/out"/msg-000000000005.msg >/dev/null || fail "newest message kept"
[ ! -e "$AI_BOX_NOTIF_DIR/out"/msg-000000000001.msg ] || fail "oldest should be dropped"
assert_contains "$(cat "$TEST_DIR/verbose.log")" "queue full, 1 dropped"

echo "ok: shim.queue_cap_drops_oldest"
