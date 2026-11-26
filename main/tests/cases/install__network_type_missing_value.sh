#!/usr/bin/env bash
# Case:   install.network_type_missing_value
# Command: ai-box install --network-type
# Context: 
# Expect:  "Error: --network-type needs a value", code 1
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" install --network-type 2>&1)"; code=$?
assert_eq "$code" "1" "exit code"
assert_contains "$out" "Error: --network-type needs a value"

echo "ok: install.network_type_missing_value"
