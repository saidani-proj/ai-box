#!/usr/bin/env bash
# Case:   install.default
# Command: ai-box install
# Context: 
# Expect:  container "ai-box" created (ubuntu:26.04), --add-host present, notifs volume mounted, work volume mounted at /work
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" install 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_log_contains "--add-host=host.docker.internal:host-gateway"
assert_log_contains "--name ai-box"
assert_log_contains "ubuntu:26.04"
assert_log_contains ".ai-box/notifs:/notifs"
assert_log_contains ".ai-box/work:/work"

echo "ok: install.default"
