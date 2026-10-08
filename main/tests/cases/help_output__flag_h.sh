#!/usr/bin/env bash
# Case:   help_output.flag_h
# Command: ai-box -h
# Context: 
# Expect:  prints usage, code 0
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" -h 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "Usage"

echo "ok: help_output.flag_h"
