#!/usr/bin/env bash
# Case:    install_host.installs_components
# Command: install-host.sh
# Expect:  listener, uninstaller, autostart entry, 0777 queue created
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
out="$("$INSTALL_HOST" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ -x "$HOME/.local/bin/ai-box-notify-bridge-listener" ] || fail "listener missing"
[ -x "$HOME/.local/bin/ai-box-notify-bridge-uninstall" ] || fail "uninstaller missing"
[ -f "$HOME/.config/autostart/ai-box-notify-bridge-listener.desktop" ] || fail "desktop entry missing"
d="$HOME/.ai-box/notifs/out"
[ -d "$d" ] || fail "queue dir missing"
assert_eq "$(stat -c %a "$d")" "777" "queue permissions"
assert_contains "$out" "installed"

echo "ok: install_host.installs_components"
