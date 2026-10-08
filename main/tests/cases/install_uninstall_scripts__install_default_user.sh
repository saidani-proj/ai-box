#!/usr/bin/env bash
# Case:   install_uninstall_scripts.install_default_user
# Command: ./install.sh
# Context: 
# Expect:  ai-box and ai-box-uninstall copied to ~/.local/bin, mode 755
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$INSTALL_SH" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ -x "$HOME/.local/bin/ai-box" ] || fail "ai-box not installed"
[ -x "$HOME/.local/bin/ai-box-uninstall" ] || fail "ai-box-uninstall not installed"
assert_contains "$out" "installed ai-box to"

echo "ok: install_uninstall_scripts.install_default_user"
