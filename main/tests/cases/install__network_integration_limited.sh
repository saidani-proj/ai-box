#!/usr/bin/env bash
# Case:   install.network_integration_limited
# Command: ai-box install --network-integration limited
# Context: 
# Expect:  --add-host present, no --network flag
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" install --network-integration limited 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_log_contains "--add-host=host.docker.internal:host-gateway"
if grep -q -- '--network' "$MOCK_DOCKER_LOG"; then fail "no --network flag expected with limited"; fi
echo "ok: install.network_integration_limited"
