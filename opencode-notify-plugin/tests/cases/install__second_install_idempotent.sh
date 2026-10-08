#!/usr/bin/env bash
# Case:    install.second_install_idempotent
# Expect:  reinstalling succeeds
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
"$INSTALL_SH" >/dev/null
out="$("$INSTALL_SH" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"

echo "ok: install.second_install_idempotent"
