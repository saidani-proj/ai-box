#!/usr/bin/env bash
# Case:   install_uninstall_scripts.uninstall_confirm_no
# Command: (see body)
# Context: 
# Expect:  "ai-box data kept" on "n", containers and ~/.ai-box preserved
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
"$AI_BOX" install >/dev/null
out="$(printf 'n\n' | "$UNINSTALL_SH" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "ai-box data kept"
grep -q '^ai-box:' "$MOCK_STATE" || fail "container should be kept"
[ -e "$HOME/.ai-box" ] || fail "~/.ai-box should be kept"

echo "ok: install_uninstall_scripts.uninstall_confirm_no"
