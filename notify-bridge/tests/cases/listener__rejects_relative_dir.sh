#!/usr/bin/env bash
# Case:    listener.rejects_relative_dir
# Command: (see body)
# Expect:  "must be absolute", code 1
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR=relative/path
out="$("$LISTENER" --once 2>&1)"; code=$?
[ "$code" -ne 0 ] || fail "expected non-zero exit code"
assert_contains "$out" "must be absolute"

echo "ok: listener.rejects_relative_dir"
