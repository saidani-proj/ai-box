#!/usr/bin/env bash
# Case:   version.after_command
# Command: ai-box up --version
# Context: 
# Expect:  "ai-box 1.0.0", code 0
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" up --version 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "ai-box 1.0.0"

echo "ok: version.after_command"
