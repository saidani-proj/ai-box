#!/usr/bin/env bash
# Case:    notifications.subagent_permission_not_ignored
# Expect:  child-session permission request is still notified
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
run_plugin '{"directory": "/tmp/proj", "options": {}, "sessions": {"child1": {"parentID": "root"}}, "env": {}, "events": [{"type": "permission.asked", "id": "e1", "data": {"sessionID": "child1"}, "_delay": 30}], "tailMs": 400}'
assert_log_lines 1
assert_log_contains "needs your approval"


echo "ok: notifications.subagent_permission_not_ignored"
