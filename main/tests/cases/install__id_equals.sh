#!/usr/bin/env bash
# Case:   install.id_equals
# Command: ai-box install --id=test
# Context: 
# Expect:  container "ai-box-test" created
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" install --id=test 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_log_contains "--name ai-box-test"

echo "ok: install.id_equals"
