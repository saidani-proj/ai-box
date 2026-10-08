#!/usr/bin/env bash
# Case:   install_uninstall_scripts.uninstall_no_data
# Command: (see body)
# Context: 
# Expect:  no prompt when no ai-box data exists
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
rm -rf "$HOME/.ai-box"
out="$("$UNINSTALL_SH" </dev/null 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
case "$out" in
    *"Delete this data?"*) fail "should not prompt when no data exists" ;;
esac

echo "ok: install_uninstall_scripts.uninstall_no_data"
