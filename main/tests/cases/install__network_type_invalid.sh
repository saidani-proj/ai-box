#!/usr/bin/env bash
# Case:   install.network_type_invalid
# Command: ai-box install --network-type bogus
# Context: 
# Expect:  "Error: --network-type must be one of: full, partial, private", code 1
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" install --network-type bogus 2>&1)"; code=$?
assert_eq "$code" "1" "exit code"
assert_contains "$out" "Error: --network-type must be one of: full, partial, private"

echo "ok: install.network_type_invalid"
