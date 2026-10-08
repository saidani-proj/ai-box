#!/usr/bin/env bash
# Case:    notifications.custom_notify_command_option
# Expect:  options.notifyCommand is used
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
scenario='{"directory":"/tmp/proj","options":{"notifyCommand":"$TEST_DIR/bin/notify-send"},"sessions":{"s1":{}},"env":{},"events":[{"type":"session.execution.succeeded","id":"e1","data":{"sessionID":"s1"},"_delay":30}],"tailMs":400}'
scenario=$(printf '%s' "$scenario" | sed "s|\$TEST_DIR|$TEST_DIR|g")
run_plugin "$scenario"
assert_log_lines 1

echo "ok: notifications.custom_notify_command_option"
