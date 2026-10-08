#!/usr/bin/env bash
# Case:    shim.message_format
# Command: (see body)
# Expect:  AN1 header, base64 fields, B= line, raw body
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
"$SHIM" -a MyApp "My Title" "My body"
f=$(ls "$AI_BOX_NOTIF_DIR/out"/msg-*.msg)
head -1 "$f" | grep -qx 'AN1' || fail "missing AN1 header"
grep -q '^U=' "$f" || fail "missing U field"
grep -q '^A=' "$f" || fail "missing A field"
grep -q '^T=' "$f" || fail "missing T field"
grep -q '^B=$' "$f" || fail "missing B= line"
grep -qx 'My body' "$f" || fail "raw body missing"
t=$(grep '^T=' "$f" | cut -d= -f2- | base64 -d)
assert_eq "$t" "My Title" "decoded title"

echo "ok: shim.message_format"
