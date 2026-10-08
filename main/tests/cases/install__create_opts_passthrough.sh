#!/usr/bin/env bash
# Case:   install.create_opts_passthrough
# Command: ai-box install -- --cpus 2
# Context: 
# Expect:  extra options forwarded to docker create
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" install -- --cpus 2 -e FOO=bar 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_log_contains "--cpus 2"
assert_log_contains "-e FOO=bar"

echo "ok: install.create_opts_passthrough"
