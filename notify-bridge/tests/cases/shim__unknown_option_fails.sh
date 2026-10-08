#!/usr/bin/env bash
# Case:    shim.unknown_option_fails
# Command: notify-send-shim.sh --bogus "t" "b"
# Expect:  "unknown option", code 1
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
out="$("$SHIM" --bogus "t" "b" 2>&1)"; code=$?
assert_eq "$code" "1" "exit code"
assert_contains "$out" "unknown option"

echo "ok: shim.unknown_option_fails"
