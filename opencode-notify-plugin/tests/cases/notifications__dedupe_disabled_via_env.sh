#!/usr/bin/env bash
# Case:    notifications.dedupe_disabled_via_env
# Expect:  DEV_NOTIFY_DEDUPE=0 allows both deliveries
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
run_plugin '{"directory": "/tmp/proj", "options": {}, "sessions": {"s1": {}}, "env": {"DEV_NOTIFY_DEDUPE": "0"}, "events": [{"type": "session.execution.succeeded", "id": "e1", "data": {"sessionID": "s1"}, "_delay": 1600}, {"type": "session.execution.succeeded", "id": "e1", "data": {"sessionID": "s1"}, "_delay": 30}], "tailMs": 600}'
assert_log_lines 2


echo "ok: notifications.dedupe_disabled_via_env"
