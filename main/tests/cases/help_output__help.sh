#!/usr/bin/env bash
# Case:   help_output.help
# Command: ai-box help
# Context: 
# Expect:  prints usage, code 0
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" help 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "Usage"

echo "ok: help_output.help"
