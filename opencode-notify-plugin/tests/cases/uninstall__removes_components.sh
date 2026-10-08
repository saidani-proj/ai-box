#!/usr/bin/env bash
# Case:    uninstall.removes_components
# Expect:  plugin dir and ai-box-opencode-notify-plugin-uninstall removed
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
"$INSTALL_SH" >/dev/null
out="$("$UNINSTALL_SH" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ ! -d "$HOME/.config/opencode/plugins/ai-box-notify" ] || fail "plugin dir remains"
[ ! -e "$HOME/.local/bin/ai-box-opencode-notify-plugin-uninstall" ] || fail "uninstaller remains"

echo "ok: uninstall.removes_components"
