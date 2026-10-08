#!/usr/bin/env bash
# Case:   install_uninstall_scripts.uninstall_keep_data
# Command: (see body)
# Context: 
# Expect:  "ai-box data kept (--keep-data)", containers and ~/.ai-box preserved, no prompt
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
"$AI_BOX" install >/dev/null
out="$("$UNINSTALL_SH" --keep-data </dev/null 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "ai-box data kept (--keep-data)"
case "$out" in
    *"Delete this data?"*) fail "should not prompt with --keep-data" ;;
esac
grep -q '^ai-box:' "$MOCK_STATE" || fail "container should be kept"
[ -e "$HOME/.ai-box" ] || fail "~/.ai-box should be kept"

echo "ok: install_uninstall_scripts.uninstall_keep_data"
