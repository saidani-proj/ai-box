#!/usr/bin/env bash
# Case:   named_id.full_cycle
# Command: ai-box install --id x && ai-box up --id x && ai-box down --id x && ai-box uninstall --id x
# Context: 
# Expect:  install/up/down/uninstall cycle OK for ai-box-x, ~/.ai-box kept
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
"$AI_BOX" install --id x >/dev/null
p="$TEST_DIR/p"; mkdir -p "$p"
(cd "$p" && "$AI_BOX" up --id x >/dev/null 2>&1)
"$AI_BOX" down --id x >/dev/null
out="$("$AI_BOX" uninstall --id x 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ -d "$HOME/.ai-box" ] || fail "~/.ai-box should be kept"
[ ! -L "$HOME/.ai-box/work-x" ] || fail "work-x symlink should be removed"
if grep -q 'ai-box-x' "$MOCK_STATE"; then fail "ai-box-x should be removed"; fi

echo "ok: named_id.full_cycle"
