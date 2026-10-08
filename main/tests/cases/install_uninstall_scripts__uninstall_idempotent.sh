#!/usr/bin/env bash
# Case:   install_uninstall_scripts.uninstall_idempotent
# Command: ./uninstall.sh
# Context: 
# Expect:  "removed ai-box", code 0
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$UNINSTALL_SH" </dev/null 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "removed ai-box"

echo "ok: install_uninstall_scripts.uninstall_idempotent"
