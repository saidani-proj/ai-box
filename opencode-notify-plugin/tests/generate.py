#!/usr/bin/env python3
"""Generate one test script per leaf case in CASES.yaml."""
import glob
import json
import os
import re
import stat
import yaml

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = yaml.safe_load(open(os.path.join(HERE, 'CASES.yaml')))

LEAVES = []
def walk(nodes, prefix):
    for n in nodes:
        path = n['name'] if not prefix else f"{prefix}.{n['name']}"
        if 'children' in n:
            walk(n['children'], path)
        else:
            LEAVES.append((path, n))
walk(DATA['cases'], '')

def scenario_body(scenario, checks):
    s = json.dumps(scenario)
    return f'''setup_env
run_plugin '{s}'
{checks}
'''

OVERRIDES = {
"install.installs_plugin_files": '''setup_env
"$INSTALL_SH" >/dev/null
p="$HOME/.config/opencode/plugins/ai-box-notify"
[ -f "$p/index.js" ] || fail "index.js missing"
[ -f "$p/package.json" ] || fail "package.json missing"
[ -f "$p/opencode.json" ] || fail "opencode.json missing"
python3 -c "import json;d=json.load(open('$p/package.json'));assert d['type']=='module'"
''',
"install.installs_uninstaller_on_path": '''setup_env
"$INSTALL_SH" >/dev/null
[ -x "$HOME/.local/bin/ai-box-opencode-notify-plugin-uninstall" ] || fail "uninstaller missing"
''',
"install.adds_bin_to_rc_when_missing": '''setup_env
touch "$HOME/.bashrc"
"$INSTALL_SH" >/dev/null
grep -q '.local/bin' "$HOME/.bashrc" || fail "rc not updated"
''',
"install.no_rc_change_when_path_present": '''setup_env
touch "$HOME/.bashrc"
export PATH="$HOME/.local/bin:$PATH"
"$INSTALL_SH" >/dev/null
if grep -q '.local/bin' "$HOME/.bashrc"; then fail "rc should not be modified"; fi
''',
"install.second_install_idempotent": '''setup_env
"$INSTALL_SH" >/dev/null
out="$("$INSTALL_SH" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
''',
"install.reinstall_uninstalls_first": '''setup_env
"$INSTALL_SH" >/dev/null
p="$HOME/.config/opencode/plugins/ai-box-notify"
touch "$p/stale-file"
out="$("$INSTALL_SH" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "uninstalling first"
[ ! -e "$p/stale-file" ] || fail "stale file remains"
[ -f "$p/index.js" ] || fail "index.js missing"
''',
"install.opencode_missing": '''setup_env
out="$(PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" "$INSTALL_SH" 2>&1)"; code=$?
assert_eq "$code" "1" "exit code"
assert_contains "$out" "opencode"
[ ! -d "$HOME/.config/opencode/plugins/ai-box-notify" ] || fail "plugin dir should not exist"
''',
"uninstall.removes_components": '''setup_env
"$INSTALL_SH" >/dev/null
out="$("$UNINSTALL_SH" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ ! -d "$HOME/.config/opencode/plugins/ai-box-notify" ] || fail "plugin dir remains"
[ ! -e "$HOME/.local/bin/ai-box-opencode-notify-plugin-uninstall" ] || fail "uninstaller remains"
''',
"uninstall.reports_when_not_installed": '''setup_env
out="$("$UNINSTALL_SH" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "not installed"
''',
}

def notif_case(events, sessions=None, directory=None, options=None, env=None, tail_ms=400, checks=""):
    return {
        'directory': directory or "/tmp/proj",
        'options': options or {},
        'sessions': sessions or {},
        'env': env or {},
        'events': events,
        'tailMs': tail_ms,
    }, checks

EV = lambda t, i, data=None, _delay=30: {'type': t, 'id': i, 'data': data or {}, '_delay': _delay}

for key, (sc, checks) in {
    "notifications.succeeded_notifies": notif_case(
        [EV('session.execution.succeeded', 'e1', {'sessionID': 's1'})],
        sessions={'s1': {}},
        checks='assert_log_lines 1\nassert_log_contains "OpenCode - proj Task complete"\n'),
    "notifications.failed_notifies": notif_case(
        [EV('session.execution.failed', 'e1', {'sessionID': 's1'})], sessions={'s1': {}},
        checks='assert_log_lines 1\nassert_log_contains "Session error"\n'),
    "notifications.permission_asked_notifies": notif_case(
        [EV('permission.asked', 'e1', {'sessionID': 's1'})], sessions={'s1': {}},
        checks='assert_log_lines 1\nassert_log_contains "needs your approval"\n'),
    "notifications.form_created_notifies": notif_case(
        [EV('form.created', 'e1', {'form': {'title': 'Pick', 'fields': [{'title': 'Choose one', 'description': 'a or b'}]}})],
        checks='assert_log_lines 1\nassert_log_contains "Question: Choose one — a or b"\n'),
    "notifications.unknown_event_ignored": notif_case(
        [EV('session.idle', 'e1', {'sessionID': 's1'})], sessions={'s1': {}},
        checks='assert_log_lines 0\n'),
    "notifications.subagent_execution_ignored": notif_case(
        [EV('session.execution.succeeded', 'e1', {'sessionID': 'child1'})],
        sessions={'child1': {'parentID': 'root'}},
        checks='assert_log_lines 0\n'),
    "notifications.subagent_permission_not_ignored": notif_case(
        [EV('permission.asked', 'e1', {'sessionID': 'child1'})],
        sessions={'child1': {'parentID': 'root'}},
        checks='assert_log_lines 1\nassert_log_contains "needs your approval"\n'),
    "notifications.dedupe_same_event_once": notif_case(
        [EV('session.execution.succeeded', 'e1', {'sessionID': 's1'}),
         EV('session.execution.succeeded', 'e1', {'sessionID': 's1'})],
        sessions={'s1': {}},
        checks='assert_log_lines 1\n'),
    "notifications.dedupe_disabled_via_env": notif_case(
        [EV('session.execution.succeeded', 'e1', {'sessionID': 's1'}, _delay=1600),
         EV('session.execution.succeeded', 'e1', {'sessionID': 's1'})],
        sessions={'s1': {}}, env={'DEV_NOTIFY_DEDUPE': '0'}, tail_ms=600,
        checks='assert_log_lines 2\n'),
    "notifications.throttle_suppresses_burst": notif_case(
        [EV('session.execution.succeeded', 'e1', {'sessionID': 's1'}),
         EV('session.execution.failed', 'e2', {'sessionID': 's1'})],
        sessions={'s1': {}},
        checks='assert_log_lines 1\n'),
    "notifications.project_name_from_session": notif_case(
        [EV('session.execution.succeeded', 'e1', {'sessionID': 's1'})],
        sessions={'s1': {'location': {'directory': '/home/user/myproj'}}},
        checks='assert_log_lines 1\nassert_log_contains "OpenCode - myproj Task complete"\n'),
    "notifications.custom_notify_command_option": notif_case(
        [EV('session.execution.succeeded', 'e1', {'sessionID': 's1'})],
        sessions={'s1': {}},
        options={}, checks=None),  # placeholder replaced below
    "notifications.notify_command_env_override": notif_case(
        [EV('session.execution.succeeded', 'e1', {'sessionID': 's1'})],
        sessions={'s1': {}}, env={}, checks=None),
    "notifications.notify_send_failure_tolerated": notif_case(
        [EV('session.execution.succeeded', 'e1', {'sessionID': 's1'})],
        sessions={'s1': {}}, env={'DEV_NOTIFY_COMMAND': 'false'},
        checks='assert_log_lines 0\n'),
}.items():
    if checks is None:
        continue
    OVERRIDES[key] = scenario_body(sc, checks)

# custom command cases need the mock path, which only exists at runtime.
OVERRIDES["notifications.custom_notify_command_option"] = '''setup_env
scenario='{"directory":"/tmp/proj","options":{"notifyCommand":"$TEST_DIR/bin/notify-send"},"sessions":{"s1":{}},"env":{},"events":[{"type":"session.execution.succeeded","id":"e1","data":{"sessionID":"s1"},"_delay":30}],"tailMs":400}'
scenario=$(printf '%s' "$scenario" | sed "s|\\$TEST_DIR|$TEST_DIR|g")
run_plugin "$scenario"
assert_log_lines 1
'''
OVERRIDES["notifications.notify_command_env_override"] = '''setup_env
export DEV_NOTIFY_COMMAND="$TEST_DIR/bin/notify-send"
scenario='{"directory":"/tmp/proj","options":{},"sessions":{"s1":{}},"env":{},"events":[{"type":"session.execution.succeeded","id":"e1","data":{"sessionID":"s1"},"_delay":30}],"tailMs":400}'
run_plugin "$scenario"
assert_log_lines 1
assert_log_contains "Task complete"
'''

CASES_DIR = os.path.join(HERE, 'cases')
os.makedirs(CASES_DIR, exist_ok=True)
expected = {p.replace('.', '__') + '.sh' for p, _ in LEAVES}
for old in glob.glob(os.path.join(CASES_DIR, '*.sh')):
    if os.path.basename(old) not in expected:
        os.remove(old)
        print('removed stale', old)

for path, node in LEAVES:
    expect = node.get('expect', '')
    body = OVERRIDES.get(path)
    if body is None:
        print('WARNING: no override for', path)
        body = 'setup_env\necho "TODO"\n'
    script = f'''#!/usr/bin/env bash
# Case:    {path}
# Expect:  {expect}
set -uo pipefail
source "{os.path.join(HERE, 'lib.sh')}"
{body}
echo "ok: {path}"
'''
    fpath = os.path.join(CASES_DIR, path.replace('.', '__') + '.sh')
    with open(fpath, 'w') as f:
        f.write(script)
    os.chmod(fpath, os.stat(fpath).st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    print('wrote', fpath)
