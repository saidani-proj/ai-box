#!/usr/bin/env bash
# Case:    install_host.custom_bin_dir
# Command: (see body)
# Expect:  AI_BOX_NOTIF_BIN overrides target directory
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_BIN="$TEST_DIR/custombin"
"$INSTALL_HOST" >/dev/null
[ -x "$TEST_DIR/custombin/ai-box-notify-bridge-listener" ] || fail "listener not in custom dir"

echo "ok: install_host.custom_bin_dir"
