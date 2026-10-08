#!/usr/bin/env bash
# Case:   install.id_missing_value
# Command: ai-box install --id
# Context: 
# Expect:  "Error: --id needs a value", code 1
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" install --id 2>&1)"; code=$?
assert_eq "$code" "1" "exit code"
assert_contains "$out" "Error: --id needs a value"

echo "ok: install.id_missing_value"
