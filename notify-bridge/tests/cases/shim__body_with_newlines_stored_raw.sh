#!/usr/bin/env bash
# Case:    shim.body_with_newlines_stored_raw
# Command: (see body)
# Expect:  body kept verbatim after B=
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
"$SHIM" "t" "$(printf 'line1\nline2')"
f=$(ls "$AI_BOX_NOTIF_DIR/out"/msg-*.msg)
python3 -c "
data = open('$f').read()
body = data.split('B=\n', 1)[1]
assert body == 'line1\nline2', repr(body)
"

echo "ok: shim.body_with_newlines_stored_raw"
