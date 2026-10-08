#!/usr/bin/env bash
# Case:   install.disable_net
# Command: ai-box install --disable-net
# Context: 
# Expect:  no --add-host (explicit flag)
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" install --disable-net 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
if grep -q -- '--add-host' "$MOCK_DOCKER_LOG"; then fail "--add-host should be omitted with --disable-net"; fi

echo "ok: install.disable_net"
