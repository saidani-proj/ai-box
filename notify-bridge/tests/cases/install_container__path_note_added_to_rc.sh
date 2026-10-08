#!/usr/bin/env bash
# Case:    install_container.path_note_added_to_rc
# Command: (see body)
# Expect:  PATH export added to rc file, note printed
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
mkdir -p "$AI_BOX_NOTIF_DIR/out"
touch "$HOME/.bashrc"
out="$("$INSTALL_CONTAINER" 2>&1)"
grep -q 'Added by ai-box notify shim installer' "$HOME/.bashrc" || fail "rc not updated"
assert_contains "$out" "not in PATH"

echo "ok: install_container.path_note_added_to_rc"
