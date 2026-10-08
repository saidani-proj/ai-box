#!/usr/bin/env bash
# Case:    shim.version
# Command: notify-send-shim.sh -v
# Expect:  "notify-send (notify-bridge) 3.0.0", code 0
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
out="$("$SHIM" -v 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "notify-send (notify-bridge) 3.0.0"

echo "ok: shim.version"
