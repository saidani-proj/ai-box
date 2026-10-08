#!/usr/bin/env bash
# Case:    install_container.volume_not_writable
# Command: (see body)
# Expect:  "not writable" reported
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
mkdir -p "$AI_BOX_NOTIF_DIR"
chmod 555 "$AI_BOX_NOTIF_DIR"
out="$("$INSTALL_CONTAINER" 2>&1)"
if [ "$(id -u)" = "0" ]; then echo "SKIP: root bypasses permissions"; exit 0; fi
assert_contains "$out" "not writable"

echo "ok: install_container.volume_not_writable"
