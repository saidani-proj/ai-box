#!/usr/bin/env bash
# Case:   install_uninstall_scripts.install_unknown_option
# Command: ./install.sh --bogus
# Context: 
# Expect:  "error: install.sh takes no arguments", code 1
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$INSTALL_SH" --bogus 2>&1)"; code=$?
assert_eq "$code" "1" "exit code"
assert_contains "$out" "error: install.sh takes no arguments"

echo "ok: install_uninstall_scripts.install_unknown_option"
