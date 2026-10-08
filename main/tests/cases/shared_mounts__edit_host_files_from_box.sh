#!/usr/bin/env bash
# Case:   shared_mounts.edit_host_files_from_box
# Command: (see body)
# Context: file created in the box via /work
# Expect:  visible on host at the same path
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
"$AI_BOX" install >/dev/null
hostdir="$TEST_DIR/proj"; mkdir -p "$hostdir"
(cd "$hostdir" && "$AI_BOX" up >/dev/null 2>&1)
docker exec ai-box bash -c 'echo box-content > /work/from_box.txt'
[ -f "$hostdir/from_box.txt" ] || fail "file created in box not visible on host"
assert_contains "$(cat "$hostdir/from_box.txt")" "box-content"

echo "ok: shared_mounts.edit_host_files_from_box"
