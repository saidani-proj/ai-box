#!/usr/bin/env bash
# Case:   install_only_options.net_on_exe
# Command: ai-box exe --disable-net
# Context: 
# Expect:  error, code 1
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" exe --disable-net 2>&1)"; code=$?
assert_eq "$code" "1" "exit code"


echo "ok: install_only_options.net_on_exe"
