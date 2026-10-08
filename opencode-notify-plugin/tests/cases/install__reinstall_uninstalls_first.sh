#!/usr/bin/env bash
# Case:    install.reinstall_uninstalls_first
# Expect:  stale files removed before reinstalling
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
"$INSTALL_SH" >/dev/null
p="$HOME/.config/opencode/plugins/ai-box-notify"
touch "$p/stale-file"
out="$("$INSTALL_SH" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "uninstalling first"
[ ! -e "$p/stale-file" ] || fail "stale file remains"
[ -f "$p/index.js" ] || fail "index.js missing"

echo "ok: install.reinstall_uninstalls_first"
