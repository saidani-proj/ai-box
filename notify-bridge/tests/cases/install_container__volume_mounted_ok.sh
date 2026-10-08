#!/usr/bin/env bash
# Case:    install_container.volume_mounted_ok
# Command: (see body)
# Expect:  "mounted" reported
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
mkdir -p "$AI_BOX_NOTIF_DIR/out"
out="$("$INSTALL_CONTAINER" 2>&1)"
assert_contains "$out" "mounted"

echo "ok: install_container.volume_mounted_ok"
