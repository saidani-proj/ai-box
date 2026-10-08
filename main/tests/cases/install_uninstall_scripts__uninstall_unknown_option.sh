#!/usr/bin/env bash
# Case:   install_uninstall_scripts.uninstall_unknown_option
# Command: ./uninstall.sh --bogus
# Context: 
# Expect:  "error: unknown option", code 1
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$UNINSTALL_SH" --bogus 2>&1)"; code=$?
assert_eq "$code" "1" "exit code"
assert_contains "$out" "error: unknown option"

echo "ok: install_uninstall_scripts.uninstall_unknown_option"
