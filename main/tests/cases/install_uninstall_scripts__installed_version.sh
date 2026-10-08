#!/usr/bin/env bash
# Case:   install_uninstall_scripts.installed_version
# Command: (see body)
# Context: 
# Expect:  installed copy of ai-box runs --version
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
"$INSTALL_SH" >/dev/null
out="$("$HOME/.local/bin/ai-box" --version 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "1.0.0"

echo "ok: install_uninstall_scripts.installed_version"
