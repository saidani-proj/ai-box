#!/usr/bin/env bash
# Case:   install_only_options.notifs_on_root
# Command: ai-box root --disable-notifs
# Context: 
# Expect:  error, code 1
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" root --disable-notifs 2>&1)"; code=$?
assert_eq "$code" "1" "exit code"


echo "ok: install_only_options.notifs_on_root"
