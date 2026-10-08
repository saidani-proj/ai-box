#!/usr/bin/env bash
# Case:    install.no_rc_change_when_path_present
# Expect:  rc file untouched when BIN already in PATH
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
touch "$HOME/.bashrc"
export PATH="$HOME/.local/bin:$PATH"
"$INSTALL_SH" >/dev/null
if grep -q '.local/bin' "$HOME/.bashrc"; then fail "rc should not be modified"; fi

echo "ok: install.no_rc_change_when_path_present"
