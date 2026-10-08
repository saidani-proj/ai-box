#!/usr/bin/env bash
# Case:   install_only_options.notifs_on_down
# Command: ai-box down --disable-notifs
# Context: 
# Expect:  "Error: --disable-net/--disable-notifs only apply to install", code 1
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" down --disable-notifs 2>&1)"; code=$?
assert_eq "$code" "1" "exit code"
assert_contains "$out" "Error: --disable-net/--disable-notifs only apply to install"

echo "ok: install_only_options.notifs_on_down"
