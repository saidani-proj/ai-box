#!/usr/bin/env bash
# Case:   root.nominal
# Command: ai-box root
# Context: 
# Expect:  shell opened as root in the container
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
seed_container ai-box running
out="$("$AI_BOX" root 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "FAKE_SHELL"
assert_log_contains "docker exec -it ai-box bash"
if grep -q -- '-u' "$MOCK_DOCKER_LOG"; then fail "root should not pass -u"; fi

echo "ok: root.nominal"
