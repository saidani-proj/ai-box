#!/usr/bin/env bash
# Case:   up.container_missing
# Command: ai-box up
# Context: no prior install
# Expect:  docker error, non-zero code
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" up 2>&1)"; code=$?
[ "$code" -ne 0 ] || fail "expected non-zero exit code"


echo "ok: up.container_missing"
