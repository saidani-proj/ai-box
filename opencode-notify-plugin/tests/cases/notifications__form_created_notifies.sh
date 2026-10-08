#!/usr/bin/env bash
# Case:    notifications.form_created_notifies
# Expect:  "Question:" with form field text via notify-send
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
run_plugin '{"directory": "/tmp/proj", "options": {}, "sessions": {}, "env": {}, "events": [{"type": "form.created", "id": "e1", "data": {"form": {"title": "Pick", "fields": [{"title": "Choose one", "description": "a or b"}]}}, "_delay": 30}], "tailMs": 400}'
assert_log_lines 1
assert_log_contains "Question: Choose one — a or b"


echo "ok: notifications.form_created_notifies"
