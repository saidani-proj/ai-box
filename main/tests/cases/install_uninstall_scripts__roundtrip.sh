#!/usr/bin/env bash
# Case:   install_uninstall_scripts.roundtrip
# Command: (see body)
# Context: 
# Expect:  install then uninstall leaves no trace
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
"$INSTALL_SH" >/dev/null
[ -x "$HOME/.local/bin/ai-box" ] || fail "ai-box not installed"
out="$("$UNINSTALL_SH" </dev/null 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "removed ai-box"
[ ! -e "$HOME/.local/bin/ai-box" ] || fail "ai-box should be removed"
[ ! -e "$HOME/.local/bin/ai-box-uninstall" ] || fail "ai-box-uninstall should be removed"

echo "ok: install_uninstall_scripts.roundtrip"
