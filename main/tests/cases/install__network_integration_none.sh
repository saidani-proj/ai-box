#!/usr/bin/env bash
# Case:   install.network_integration_none
# Command: ai-box install --network-integration none
# Context: 
# Expect:  no --network flag, no --add-host
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" install --network-integration none 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
if grep -q -- '--network' "$MOCK_DOCKER_LOG"; then fail "no --network flag expected with none"; fi
if grep -q -- '--add-host' "$MOCK_DOCKER_LOG"; then fail "no --add-host expected with none"; fi
echo "ok: install.network_integration_none"
