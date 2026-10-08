#!/usr/bin/env bash
# Case:   install_uninstall_scripts.reinstall_keeps_data
# Command: (see body)
# Context: 
# Expect:  existing install uninstalled with --keep-data, scripts reinstalled, containers and ~/.ai-box preserved
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
"$INSTALL_SH" >/dev/null
"$AI_BOX" install >/dev/null
out="$("$INSTALL_SH" </dev/null 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "existing ai-box installation"
assert_contains "$out" "installed ai-box to"
grep -q '^ai-box:' "$MOCK_STATE" || fail "container should be kept"
[ -e "$HOME/.ai-box" ] || fail "~/.ai-box should be kept"
[ -x "$HOME/.local/bin/ai-box" ] || fail "ai-box should be reinstalled"

echo "ok: install_uninstall_scripts.reinstall_keeps_data"
