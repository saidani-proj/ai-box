#!/usr/bin/env bash
# Case:    shim.id_increments
# Command: (see body)
# Expect:  two calls produce msg-...-001 and msg-...-002
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
"$SHIM" "one" "1"
"$SHIM" "two" "2"
ls "$AI_BOX_NOTIF_DIR/out"/msg-000000000001.msg >/dev/null 2>&1 || fail "first id file missing"
ls "$AI_BOX_NOTIF_DIR/out"/msg-000000000002.msg >/dev/null 2>&1 || fail "second id file missing"

echo "ok: shim.id_increments"
