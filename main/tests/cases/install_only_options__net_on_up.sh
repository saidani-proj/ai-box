#!/usr/bin/env bash
# Case:   install_only_options.net_on_up
# Command: ai-box up --disable-net
# Context: 
# Expect:  "Error: --disable-net/--disable-notifs only apply to install", code 1
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" up --disable-net 2>&1)"; code=$?
assert_eq "$code" "1" "exit code"
assert_contains "$out" "Error: --disable-net/--disable-notifs only apply to install"

echo "ok: install_only_options.net_on_up"
