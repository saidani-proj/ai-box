#!/usr/bin/env bash
# Case:   unknown_command
# Command: ai-box foobar
# Context: 
# Expect:  "Unknown command: foobar" + usage, code 1
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" foobar 2>&1)"; code=$?
assert_eq "$code" "1" "exit code"
assert_contains "$out" "Unknown command: foobar"
assert_contains "$out" "Usage"

echo "ok: unknown_command"
