#!/usr/bin/env bash
# Case:   install.network_type_partial
# Command: ai-box install --network-type partial
# Context: 
# Expect:  --add-host present, no --network flag
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" install --network-type partial 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_log_contains "--add-host=host.docker.internal:host-gateway"
if grep -q -- '--network' "$MOCK_DOCKER_LOG"; then fail "no --network flag expected with partial"; fi
echo "ok: install.network_type_partial"
