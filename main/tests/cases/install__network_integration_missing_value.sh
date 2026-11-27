#!/usr/bin/env bash
# Case:   install.network_integration_missing_value
# Command: ai-box install --network-integration
# Context: 
# Expect:  "Error: --network-integration needs a value", code 1
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" install --network-integration 2>&1)"; code=$?
assert_eq "$code" "1" "exit code"
assert_contains "$out" "Error: --network-integration needs a value"

echo "ok: install.network_integration_missing_value"
