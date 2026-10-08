#!/usr/bin/env bash
# Case:    install.opencode_missing
# Expect:  "opencode" not found error, code 1, nothing installed
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
out="$(PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" "$INSTALL_SH" 2>&1)"; code=$?
assert_eq "$code" "1" "exit code"
assert_contains "$out" "opencode"
[ ! -d "$HOME/.config/opencode/plugins/ai-box-notify" ] || fail "plugin dir should not exist"

echo "ok: install.opencode_missing"
