#!/usr/bin/env bash
# Case:    install_container.path_already_present
# Command: (see body)
# Expect:  no rc modification when BIN already in PATH
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
mkdir -p "$AI_BOX_NOTIF_DIR/out"
touch "$HOME/.bashrc"
export PATH="$HOME/.local/bin:$PATH"
out="$("$INSTALL_CONTAINER" 2>&1)"
if grep -q 'Added by ai-box notify shim installer' "$HOME/.bashrc"; then fail "rc should not be modified"; fi

echo "ok: install_container.path_already_present"
