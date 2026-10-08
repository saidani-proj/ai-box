#!/usr/bin/env bash
# Case:   named_id.work_dir_per_id
# Command: ai-box install --id test
# Context: 
# Expect:  ~/.ai-box/work-test mounted at /work; ~/.ai-box/work-test symlink after up
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
"$AI_BOX" install --id test >/dev/null
assert_log_contains ".ai-box/work-test:/work"
p="$TEST_DIR/p"; mkdir -p "$p"
(cd "$p" && "$AI_BOX" up --id test >/dev/null 2>&1)
assert_eq "$(readlink "$HOME/.ai-box/work-test")" "$p" "work-test symlink"
[ ! -L "$HOME/.ai-box/work" ] || fail "default work symlink should not be created"

echo "ok: named_id.work_dir_per_id"
