#!/usr/bin/env bash
# Case:   uninstall.nominal
# Command: ai-box uninstall
# Context: 
# Expect:  container stopped and removed, work symlink deleted, ~/.ai-box kept
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
"$AI_BOX" install >/dev/null
p="$TEST_DIR/p"; mkdir -p "$p"
(cd "$p" && "$AI_BOX" up >/dev/null 2>&1)
out="$("$AI_BOX" uninstall 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ ! -L "$HOME/.ai-box/work" ] || fail "work symlink should be removed"
[ -d "$HOME/.ai-box" ] || fail "~/.ai-box should be kept"
if grep -q 'ai-box' "$MOCK_STATE"; then fail "container should be removed"; fi

echo "ok: uninstall.nominal"
