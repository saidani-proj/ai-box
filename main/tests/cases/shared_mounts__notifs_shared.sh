#!/usr/bin/env bash
# Case:   shared_mounts.notifs_shared
# Command: (see body)
# Context: file in ~/.ai-box/notifs
# Expect:  visible at /notifs inside the box
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
"$AI_BOX" install >/dev/null
p="$TEST_DIR/p"; mkdir -p "$p"
(cd "$p" && "$AI_BOX" up >/dev/null 2>&1)
docker exec ai-box bash -c 'echo note > /notifs/note.txt'
[ -f "$HOME/.ai-box/notifs/note.txt" ] || fail "file written in box not visible on host"
assert_contains "$(cat "$HOME/.ai-box/notifs/note.txt")" "note"

echo "ok: shared_mounts.notifs_shared"
