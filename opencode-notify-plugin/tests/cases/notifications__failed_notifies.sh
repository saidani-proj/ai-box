#!/usr/bin/env bash
# Case:    notifications.failed_notifies
# Expect:  "Session error" via notify-send
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
run_plugin '{"directory": "/tmp/proj", "options": {}, "sessions": {"s1": {}}, "env": {}, "events": [{"type": "session.execution.failed", "id": "e1", "data": {"sessionID": "s1"}, "_delay": 30}], "tailMs": 400}'
assert_log_lines 1
assert_log_contains "Session error"


echo "ok: notifications.failed_notifies"
