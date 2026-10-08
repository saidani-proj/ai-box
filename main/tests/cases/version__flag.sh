#!/usr/bin/env bash
# Case:   version.flag
# Command: ai-box --version
# Context: 
# Expect:  "ai-box 1.0.0", code 0
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" --version 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "ai-box 1.0.0"

echo "ok: version.flag"
