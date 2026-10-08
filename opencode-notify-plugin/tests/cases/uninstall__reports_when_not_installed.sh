#!/usr/bin/env bash
# Case:    uninstall.reports_when_not_installed
# Expect:  "not installed" reported
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
out="$("$UNINSTALL_SH" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "not installed"

echo "ok: uninstall.reports_when_not_installed"
