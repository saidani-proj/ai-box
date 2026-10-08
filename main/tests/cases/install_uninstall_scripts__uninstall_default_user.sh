#!/usr/bin/env bash
# Case:   install_uninstall_scripts.uninstall_default_user
# Command: ./uninstall.sh
# Context: 
# Expect:  ai-box and ai-box-uninstall removed from ~/.local/bin
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
"$INSTALL_SH" >/dev/null
out="$("$UNINSTALL_SH" </dev/null 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ ! -e "$HOME/.local/bin/ai-box" ] || fail "ai-box should be removed"
[ ! -e "$HOME/.local/bin/ai-box-uninstall" ] || fail "ai-box-uninstall should be removed"

echo "ok: install_uninstall_scripts.uninstall_default_user"
