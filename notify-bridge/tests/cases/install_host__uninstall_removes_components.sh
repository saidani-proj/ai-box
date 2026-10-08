#!/usr/bin/env bash
# Case:    install_host.uninstall_removes_components
# Command: uninstall-host.sh
# Expect:  all host components removed
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
"$INSTALL_HOST" >/dev/null
out="$("$UNINSTALL_HOST" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ ! -e "$HOME/.local/bin/ai-box-notify-bridge-listener" ] || fail "listener still present"
[ ! -e "$HOME/.local/bin/ai-box-notify-bridge-uninstall" ] || fail "uninstaller still present"
[ ! -e "$HOME/.config/autostart/ai-box-notify-bridge-listener.desktop" ] || fail "desktop entry still present"
[ ! -e "$HOME/.ai-box/notifs" ] || fail "notifs dir still present"
assert_contains "$out" "host uninstalled"

echo "ok: install_host.uninstall_removes_components"
