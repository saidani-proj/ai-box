#!/usr/bin/env bash
# Case:    listener.version
# Command: listener.sh --version
# Expect:  "1.0.0", code 0
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
out="$("$LISTENER" --version 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "1.0.0"

echo "ok: listener.version"
