#!/usr/bin/env bash
# Case:    install_container.volume_missing
# Command: (see body)
# Expect:  "does not exist" reported
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/no-such-dir"
out="$("$INSTALL_CONTAINER" 2>&1)"
assert_contains "$out" "does not exist"

echo "ok: install_container.volume_missing"
