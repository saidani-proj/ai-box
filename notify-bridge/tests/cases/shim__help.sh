#!/usr/bin/env bash
# Case:    shim.help
# Command: notify-send-shim.sh --help
# Expect:  prints usage, code 0
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
out="$("$SHIM" --help 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "Usage"

echo "ok: shim.help"
