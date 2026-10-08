#!/usr/bin/env bash
# Case:   install_uninstall_scripts.uninstall_help_long
# Command: ./uninstall.sh --help
# Context: 
# Expect:  "Usage", code 0
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$UNINSTALL_SH" --help 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "Usage"
assert_contains "$out" "Usage"

echo "ok: install_uninstall_scripts.uninstall_help_long"
