#!/usr/bin/env bash
# Case:    install.adds_bin_to_rc_when_missing
# Expect:  PATH export added to rc file
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
touch "$HOME/.bashrc"
"$INSTALL_SH" >/dev/null
grep -q '.local/bin' "$HOME/.bashrc" || fail "rc not updated"

echo "ok: install.adds_bin_to_rc_when_missing"
