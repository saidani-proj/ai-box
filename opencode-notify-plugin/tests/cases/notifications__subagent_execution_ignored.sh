#!/usr/bin/env bash
# Case:    notifications.subagent_execution_ignored
# Expect:  child-session completion is not notified
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
run_plugin '{"directory": "/tmp/proj", "options": {}, "sessions": {"child1": {"parentID": "root"}}, "env": {}, "events": [{"type": "session.execution.succeeded", "id": "e1", "data": {"sessionID": "child1"}, "_delay": 30}], "tailMs": 400}'
assert_log_lines 0


echo "ok: notifications.subagent_execution_ignored"
