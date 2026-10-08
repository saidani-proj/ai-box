#!/usr/bin/env bash
# Case:   help_output.no_argument
# Command: ai-box
# Context: 
# Expect:  error '"Unknown command"' + usage, code 1
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" 2>&1)"; code=$?
assert_eq "$code" "1" "exit code"
assert_contains "$out" "Unknown command"
assert_contains "$out" "Usage"

echo "ok: help_output.no_argument"
