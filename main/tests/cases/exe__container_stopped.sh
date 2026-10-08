#!/usr/bin/env bash
# Case:   exe.container_stopped
# Command: ai-box exe
# Context: 
# Expect:  docker error, non-zero code
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" exe 2>&1)"; code=$?
[ "$code" -ne 0 ] || fail "expected non-zero exit code"


echo "ok: exe.container_stopped"
