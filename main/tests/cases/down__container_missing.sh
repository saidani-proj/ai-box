#!/usr/bin/env bash
# Case:   down.container_missing
# Command: ai-box down
# Context: 
# Expect:  docker error, non-zero code
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" down 2>&1)"; code=$?
[ "$code" -ne 0 ] || fail "expected non-zero exit code"


echo "ok: down.container_missing"
