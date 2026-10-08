#!/usr/bin/env bash
# Case:    notifications.project_name_from_session
# Expect:  title uses the session directory name
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
run_plugin '{"directory": "/tmp/proj", "options": {}, "sessions": {"s1": {"location": {"directory": "/home/user/myproj"}}}, "env": {}, "events": [{"type": "session.execution.succeeded", "id": "e1", "data": {"sessionID": "s1"}, "_delay": 30}], "tailMs": 400}'
assert_log_lines 1
assert_log_contains "OpenCode - myproj Task complete"


echo "ok: notifications.project_name_from_session"
