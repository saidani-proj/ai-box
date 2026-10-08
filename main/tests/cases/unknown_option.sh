#!/usr/bin/env bash
# Case:   unknown_option
# Command: ai-box up --bogus
# Context: 
# Expect:  "Unknown option: --bogus" + usage, code 1
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" up --bogus 2>&1)"; code=$?
assert_eq "$code" "1" "exit code"
assert_contains "$out" "Unknown option: --bogus"
assert_contains "$out" "Usage"

echo "ok: unknown_option"
