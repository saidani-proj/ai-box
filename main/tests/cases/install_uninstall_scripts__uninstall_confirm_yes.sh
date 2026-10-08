#!/usr/bin/env bash
# Case:   install_uninstall_scripts.uninstall_confirm_yes
# Command: (see body)
# Context: 
# Expect:  "Delete this data?" prompt, containers and ~/.ai-box removed on "y"
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
"$AI_BOX" install >/dev/null
grep -q '^ai-box:' "$MOCK_STATE" || fail "container not created"
out="$(printf 'y\n' | "$UNINSTALL_SH" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "Delete this data?"
assert_contains "$out" "ai-box data removed"
if grep -q '^ai-box' "$MOCK_STATE"; then fail "container should be removed"; fi
[ ! -e "$HOME/.ai-box" ] || fail "~/.ai-box should be removed"

echo "ok: install_uninstall_scripts.uninstall_confirm_yes"
