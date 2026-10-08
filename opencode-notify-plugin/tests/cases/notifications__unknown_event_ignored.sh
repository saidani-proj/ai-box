#!/usr/bin/env bash
# Case:    notifications.unknown_event_ignored
# Expect:  no notify-send call
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
run_plugin '{"directory": "/tmp/proj", "options": {}, "sessions": {"s1": {}}, "env": {}, "events": [{"type": "session.idle", "id": "e1", "data": {"sessionID": "s1"}, "_delay": 30}], "tailMs": 400}'
assert_log_lines 0


echo "ok: notifications.unknown_event_ignored"
