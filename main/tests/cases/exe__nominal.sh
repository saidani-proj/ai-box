#!/usr/bin/env bash
# Case:   exe.nominal
# Command: ai-box exe
# Context: container running
# Expect:  shell opened as user (host uid/gid), workdir /work, symlink unmodified
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
seed_container ai-box running
p="$TEST_DIR/p"; mkdir -p "$p"
ln -s "$p" "$HOME/.ai-box/work"
before="$(readlink "$HOME/.ai-box/work")"
out="$("$AI_BOX" exe 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "FAKE_SHELL"
assert_log_contains "-u $(id -u):$(id -g)"
assert_log_contains "-w /work"
after="$(readlink "$HOME/.ai-box/work")"
assert_eq "$after" "$before" "symlink must not change"

echo "ok: exe.nominal"
