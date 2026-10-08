#!/usr/bin/env bash
# Case:    notifications.throttle_suppresses_burst
# Expect:  second event inside 1.5s is dropped
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
run_plugin '{"directory": "/tmp/proj", "options": {}, "sessions": {"s1": {}}, "env": {}, "events": [{"type": "session.execution.succeeded", "id": "e1", "data": {"sessionID": "s1"}, "_delay": 30}, {"type": "session.execution.failed", "id": "e2", "data": {"sessionID": "s1"}, "_delay": 30}], "tailMs": 400}'
assert_log_lines 1


echo "ok: notifications.throttle_suppresses_burst"
