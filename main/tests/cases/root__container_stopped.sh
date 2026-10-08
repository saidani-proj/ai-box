#!/usr/bin/env bash
# Case:   root.container_stopped
# Command: ai-box root
# Context: 
# Expect:  docker error, non-zero code
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" root 2>&1)"; code=$?
[ "$code" -ne 0 ] || fail "expected non-zero exit code"


echo "ok: root.container_stopped"
