#!/usr/bin/env bash
# Case:   up.notifs_dir_created
# Command: (see body)
# Context: 
# Expect:  ~/.ai-box/notifs exists after up
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
"$AI_BOX" install >/dev/null
p="$TEST_DIR/p"; mkdir -p "$p"
(cd "$p" && "$AI_BOX" up >/dev/null 2>&1)
[ -d "$HOME/.ai-box/notifs" ] || fail "notifs dir not created"

echo "ok: up.notifs_dir_created"
