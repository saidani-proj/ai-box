#!/usr/bin/env bash
# Case:    notifications.notify_command_env_override
# Expect:  DEV_NOTIFY_COMMAND is used
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
export DEV_NOTIFY_COMMAND="$TEST_DIR/bin/notify-send"
scenario='{"directory":"/tmp/proj","options":{},"sessions":{"s1":{}},"env":{},"events":[{"type":"session.execution.succeeded","id":"e1","data":{"sessionID":"s1"},"_delay":30}],"tailMs":400}'
run_plugin "$scenario"
assert_log_lines 1
assert_log_contains "Task complete"

echo "ok: notifications.notify_command_env_override"
