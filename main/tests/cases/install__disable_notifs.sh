#!/usr/bin/env bash
# Case:   install.disable_notifs
# Command: ai-box install --disable-notifs
# Context: 
# Expect:  no notifs volume mounted
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
out="$("$AI_BOX" install --disable-notifs 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
if grep -q 'notifs:/notifs' "$MOCK_DOCKER_LOG"; then fail "notifs volume should be omitted with --disable-notifs"; fi

echo "ok: install.disable_notifs"
