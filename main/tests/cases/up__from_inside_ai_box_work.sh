#!/usr/bin/env bash
# Case:   up.from_inside_ai_box_work
# Command: ai-box up
# Context: $PWD = ~/.ai-box/work or one of its subdirectories
# Expect:  error "$PWD is inside ~/.ai-box/work", code 1, symlink unchanged
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
mkdir -p "$HOME/.ai-box/work"
out="$(cd "$HOME/.ai-box/work" && "$AI_BOX" up 2>&1)"; code=$?
assert_eq "$code" "1" "exit code"
assert_contains "$out" "is inside ~/.ai-box/work"
[ ! -L "$HOME/.ai-box/work" ] || fail "symlink created unexpectedly"

echo "ok: up.from_inside_ai_box_work"
