#!/usr/bin/env bash
# Case:   install.docker_missing
# Command: (see body)
# Context: docker not installed / create failure
# Expect:  error propagated, non-zero code
set -uo pipefail
source "/work/main/tests/lib.sh"
export DOCKER_ABSENT=1
setup_env
out="$("$AI_BOX" install 2>&1)"; code=$?
[ "$code" -ne 0 ] || fail "expected non-zero exit code"

echo "ok: install.docker_missing"
