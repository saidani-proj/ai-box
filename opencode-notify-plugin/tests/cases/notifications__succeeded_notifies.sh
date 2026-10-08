#!/usr/bin/env bash
# Case:    notifications.succeeded_notifies
# Expect:  "Task complete" via notify-send
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
run_plugin '{"directory": "/tmp/proj", "options": {}, "sessions": {"s1": {}}, "env": {}, "events": [{"type": "session.execution.succeeded", "id": "e1", "data": {"sessionID": "s1"}, "_delay": 30}], "tailMs": 400}'
assert_log_lines 1
assert_log_contains "OpenCode - proj Task complete"


echo "ok: notifications.succeeded_notifies"
