#!/usr/bin/env bash
# Case:    install_host.reinstall_uninstalls_first
# Command: (see body)
# Expect:  previous install removed before reinstalling, code 0
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
"$INSTALL_HOST" >/dev/null
touch "$HOME/.ai-box/notifs/old-marker"
out="$("$INSTALL_HOST" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ ! -e "$HOME/.ai-box/notifs/old-marker" ] || fail "old install not removed"
assert_contains "$out" "uninstalling first"
[ -x "$HOME/.local/bin/ai-box-notify-bridge-listener" ] || fail "listener missing after reinstall"

echo "ok: install_host.reinstall_uninstalls_first"
