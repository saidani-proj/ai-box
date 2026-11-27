#!/usr/bin/env bash
# Case:   install.network_integration_invalid
# Command: ai-box install --network-integration bogus
# Context: 
# Expect:  "Error: --network-integration must be one of: full, limited, none", code 1
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" install --network-integration bogus 2>&1)"; code=$?
assert_eq "$code" "1" "exit code"
assert_contains "$out" "Error: --network-integration must be one of: full, limited, none"

echo "ok: install.network_integration_invalid"
