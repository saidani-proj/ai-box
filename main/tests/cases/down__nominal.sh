#!/usr/bin/env bash
# Case:   down.nominal
# Command: ai-box down
# Context: 
# Expect:  container stopped, code 0
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
"$AI_BOX" install >/dev/null
out="$("$AI_BOX" down 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
grep -q '^ai-box:stopped' "$MOCK_STATE" || fail "container not stopped"

echo "ok: down.nominal"
