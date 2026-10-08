#!/usr/bin/env bash
# Case:   up.symlink_updated
# Command: (see body)
# Context: 
# Expect:  running up from another directory re-points ~/.ai-box/work
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
"$AI_BOX" install >/dev/null
a="$TEST_DIR/a"; b="$TEST_DIR/b"; mkdir -p "$a" "$b"
(cd "$a" && "$AI_BOX" up >/dev/null 2>&1)
assert_eq "$(readlink "$HOME/.ai-box/work")" "$a" "symlink should point to a"
(cd "$b" && "$AI_BOX" up >/dev/null 2>&1)
assert_eq "$(readlink "$HOME/.ai-box/work")" "$b" "symlink should point to b"

echo "ok: up.symlink_updated"
