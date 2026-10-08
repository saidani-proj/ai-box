#!/usr/bin/env bash
# Case:    install.installs_uninstaller_on_path
# Expect:  ai-box-opencode-notify-plugin-uninstall in ~/.local/bin
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
"$INSTALL_SH" >/dev/null
[ -x "$HOME/.local/bin/ai-box-opencode-notify-plugin-uninstall" ] || fail "uninstaller missing"

echo "ok: install.installs_uninstaller_on_path"
