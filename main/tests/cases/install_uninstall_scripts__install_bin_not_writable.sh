#!/usr/bin/env bash
# Case:   install_uninstall_scripts.install_bin_not_writable
# Command: ./install.sh
# Context: bin_dir not writable
# Expect:  clear error message, code 1
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
mkdir -p "$HOME/.local/bin"
chmod 555 "$HOME/.local/bin"
out="$("$INSTALL_SH" 2>&1)"; code=$?
if [ "$(id -u)" = "0" ]; then
    echo "SKIP: root bypasses permission bits"
    exit 0
fi
assert_eq "$code" "1" "exit code"
assert_contains "$out" "not writable"

echo "ok: install_uninstall_scripts.install_bin_not_writable"
