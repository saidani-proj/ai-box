#!/usr/bin/env bash
# Case:   up.nominal
# Command: ai-box up
# Context: container exists
# Expect:  container stopped then started, ~/.ai-box/work points to $PWD, interactive shell opened, working directory /work, uid/gid same as host
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
"$AI_BOX" install >/dev/null
hostdir="$TEST_DIR/proj"; mkdir -p "$hostdir"
out="$(cd "$hostdir" && "$AI_BOX" up 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_eq "$(readlink "$HOME/.ai-box/work")" "$hostdir" "workdir symlink"
assert_log_contains "-u $(id -u):$(id -g)"
assert_log_contains "-w /work"
grep -q '^ai-box:running' "$MOCK_STATE" || fail "container not running"

echo "ok: up.nominal"
