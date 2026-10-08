#!/usr/bin/env bash
# Case:    notifications.notify_send_failure_tolerated
# Expect:  failing notify command does not crash the plugin
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
run_plugin '{"directory": "/tmp/proj", "options": {}, "sessions": {"s1": {}}, "env": {"DEV_NOTIFY_COMMAND": "false"}, "events": [{"type": "session.execution.succeeded", "id": "e1", "data": {"sessionID": "s1"}, "_delay": 30}], "tailMs": 400}'
assert_log_lines 0


echo "ok: notifications.notify_send_failure_tolerated"
