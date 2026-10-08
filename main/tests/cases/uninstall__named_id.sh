#!/usr/bin/env bash
# Case:   uninstall.named_id
# Command: ai-box uninstall --id test
# Context: 
# Expect:  container ai-box-test removed, ~/.ai-box kept
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
"$AI_BOX" install --id test >/dev/null
p="$TEST_DIR/p"; mkdir -p "$p"
(cd "$p" && "$AI_BOX" up --id test >/dev/null 2>&1)
out="$("$AI_BOX" uninstall --id test 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
if grep -q '^ai-box-test:' "$MOCK_STATE"; then fail "ai-box-test should be removed"; fi
[ ! -L "$HOME/.ai-box/work-test" ] || fail "work-test symlink should be removed"
[ -d "$HOME/.ai-box" ] || fail "~/.ai-box should be kept"

echo "ok: uninstall.named_id"
