#!/usr/bin/env python3
"""Generate one test script per leaf case in CASES.yaml."""
import glob
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

SCRIPT_MAP = {
    'notify-send-shim.sh': '"$SHIM"',
    'listener.sh': '"$LISTENER"',
    'install-host.sh': '"$INSTALL_HOST"',
    'uninstall-host.sh': '"$UNINSTALL_HOST"',
    'install-container.sh': '"$INSTALL_CONTAINER"',
    'uninstall-container.sh': '"$UNINSTALL_CONTAINER"',
}

def cmd_subst(c):
    for k, v in SCRIPT_MAP.items():
        c = c.replace(k, v)
    return c

def code_check(expect):
    m = re.search(r'code\s+(\d+)', expect)
    if m:
        return f'assert_eq "$code" "{m.group(1)}" "exit code"'
    if re.search(r'non[- ]?zero|non nul', expect, re.I):
        return '[ "$code" -ne 0 ] || fail "expected non-zero exit code"'
    return ':'

def literal_checks(expect):
    lines = []
    for lit in re.findall(r'"([^"]+)"', expect):
        lines.append(f'assert_contains "$out" "{lit}"')
    if re.search(r'usage', expect, re.I):
        lines.append('assert_contains "$out" "Usage"')
    return '\n'.join(lines)

OVERRIDES = {
"shim.replace_id_ignored": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
out="$("$SHIM" -r 42 "t" "b" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
ls "$AI_BOX_NOTIF_DIR/out"/msg-*.msg >/dev/null 2>&1 || fail "message not written"
''',
"shim.invalid_urgency_defaults_to_normal": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
out="$("$SHIM" -u bogus "t" "b" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
f=$(ls "$AI_BOX_NOTIF_DIR/out"/msg-*.msg)
assert_contains "$(cat "$f")" "$(printf '%s' normal | base64 | tr -d '\\n' | sed 's/^/U=/')"
''',
"shim.message_format": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
"$SHIM" -a MyApp "My Title" "My body"
f=$(ls "$AI_BOX_NOTIF_DIR/out"/msg-*.msg)
head -1 "$f" | grep -qx 'AN1' || fail "missing AN1 header"
grep -q '^U=' "$f" || fail "missing U field"
grep -q '^A=' "$f" || fail "missing A field"
grep -q '^T=' "$f" || fail "missing T field"
grep -q '^B=$' "$f" || fail "missing B= line"
grep -qx 'My body' "$f" || fail "raw body missing"
t=$(grep '^T=' "$f" | cut -d= -f2- | base64 -d)
assert_eq "$t" "My Title" "decoded title"
''',
"shim.body_with_newlines_stored_raw": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
"$SHIM" "t" "$(printf 'line1\\nline2')"
f=$(ls "$AI_BOX_NOTIF_DIR/out"/msg-*.msg)
python3 -c "
data = open('$f').read()
body = data.split('B=\\n', 1)[1]
assert body == 'line1\\nline2', repr(body)
"
''',
"shim.id_increments": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
"$SHIM" "one" "1"
"$SHIM" "two" "2"
ls "$AI_BOX_NOTIF_DIR/out"/msg-000000000001.msg >/dev/null 2>&1 || fail "first id file missing"
ls "$AI_BOX_NOTIF_DIR/out"/msg-000000000002.msg >/dev/null 2>&1 || fail "second id file missing"
''',
"shim.print_id": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
out="$("$SHIM" -p "t" "b")"; code=$?
assert_eq "$code" "0" "exit code"
assert_eq "$out" "1" "printed id"
''',
"shim.option_parsing": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
"$SHIM" -u critical -a MyApp -i myicon -t 5000 "t" "b"
f=$(ls "$AI_BOX_NOTIF_DIR/out"/msg-*.msg)
check() { local line="$1" want="$2"; local v; v=$(grep "^$line=" "$f" | cut -d= -f2- | base64 -d); assert_eq "$v" "$want" "field $line"; }
check U critical
check A MyApp
check I myicon
v=$(grep '^X=' "$f" | cut -d= -f2-); assert_eq "$v" "5000" "field X"
''',
"shim.queue_cap_drops_oldest": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_MAX=3 AI_BOX_NOTIF_VERBOSE=1
for i in 1 2 3 4 5; do "$SHIM" "m$i" "b$i" 2>>"$TEST_DIR/verbose.log"; done
[ "$(ls "$AI_BOX_NOTIF_DIR/out"/msg-*.msg | wc -l)" = "3" ] || fail "expected 3 messages kept"
ls "$AI_BOX_NOTIF_DIR/out"/msg-000000000005.msg >/dev/null || fail "newest message kept"
[ ! -e "$AI_BOX_NOTIF_DIR/out"/msg-000000000001.msg ] || fail "oldest should be dropped"
assert_contains "$(cat "$TEST_DIR/verbose.log")" "queue full, 1 dropped"
''',
"shim.queue_missing_fails": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/afile"
touch "$TEST_DIR/afile"
out="$("$SHIM" "t" "b" 2>&1)"; code=$?
[ "$code" -ne 0 ] || fail "expected non-zero exit code"
assert_contains "$out" "queue missing"
''',
"listener.rejects_relative_dir": '''setup_env
export AI_BOX_NOTIF_DIR=relative/path
out="$("$LISTENER" --once 2>&1)"; code=$?
[ "$code" -ne 0 ] || fail "expected non-zero exit code"
assert_contains "$out" "must be absolute"
''',
"listener.rejects_shim_as_send": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_SEND="$SHIM"
out="$("$LISTENER" --once 2>&1)"; code=$?
[ "$code" -ne 0 ] || fail "expected non-zero exit code"
assert_contains "$out" "shim"
''',
"listener.missing_send_binary": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_SEND=definitely-not-a-real-binary
out="$("$LISTENER" --once 2>&1)"; code=$?
[ "$code" -ne 0 ] || fail "expected non-zero exit code"
assert_contains "$out" "notify-send not found in PATH"
''',
"listener.once_drains_queue": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_SEND="$TEST_DIR/bin/notify-send"
mkdir -p "$AI_BOX_NOTIF_DIR/out"
"$SHIM" "My Title" "My body"
out="$("$LISTENER" --once 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$(cat "$NS_LOG")" "My Title My body"
''',
"listener.delivers_message_after_start": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_SEND="$TEST_DIR/bin/notify-send"
mkdir -p "$AI_BOX_NOTIF_DIR"
timeout 3 "$LISTENER" --interval 1 &
sleep 1
"$SHIM" "T" "B"
sleep 2
assert_log_contains "T B"
''',
"listener.full_argument_reconstruction": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_SEND="$TEST_DIR/bin/notify-send"
mkdir -p "$AI_BOX_NOTIF_DIR"
timeout 3 "$LISTENER" --interval 1 &
sleep 1
AI_BOX_NOTIF_DIR="$TEST_DIR/notifs" "$SHIM" -u critical -a MyApp -i myicon -t 5000 "Title" "Body"
sleep 2
assert_contains "$(cat "$NS_LOG")" "-a MyApp -i myicon -u critical -t 5000 Title Body"
''',
"listener.hints_forwarded": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_SEND="$TEST_DIR/bin/notify-send"
mkdir -p "$AI_BOX_NOTIF_DIR"
timeout 3 "$LISTENER" --interval 1 &
sleep 1
AI_BOX_NOTIF_DIR="$TEST_DIR/notifs" "$SHIM" --hint "a=b" --hint "c=d" "Title" "Body"
sleep 2
assert_contains "$(cat "$NS_LOG")" "--hint=a=b"
assert_contains "$(cat "$NS_LOG")" "--hint=c=d"
''',
"listener.debris_dropped": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_SEND="$TEST_DIR/bin/notify-send"
mkdir -p "$AI_BOX_NOTIF_DIR"
timeout 3 "$LISTENER" --interval 1 &
sleep 1
echo "garbage" > "$AI_BOX_NOTIF_DIR/out/msg-000000000099.msg"
sleep 2
[ ! -e "$AI_BOX_NOTIF_DIR/out/msg-000000000099.msg" ] || fail "debris not removed"
''',
"listener.stale_in_files_reaped": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_SEND="$TEST_DIR/bin/notify-send"
export AI_BOX_NOTIF_STALE=60
mkdir -p "$AI_BOX_NOTIF_DIR"
timeout 3 "$LISTENER" --interval 1 &
sleep 1
old="$AI_BOX_NOTIF_DIR/out/.in.9991"; new="$AI_BOX_NOTIF_DIR/out/.in.9992"
: > "$old"; : > "$new"
touch -d '2 minutes ago' "$old"
sleep 2
[ ! -e "$old" ] || fail "stale .in file kept"
[ -e "$new" ] || fail "recent .in file removed"
''',
"listener.second_listener_exits_via_lock": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
export AI_BOX_NOTIF_SEND="$TEST_DIR/bin/notify-send"
mkdir -p "$AI_BOX_NOTIF_DIR"
timeout 3 "$LISTENER" --interval 1 &
sleep 1
out="$("$LISTENER" --once 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
''',
"install_host.installs_components": '''setup_env
out="$("$INSTALL_HOST" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ -x "$HOME/.local/bin/ai-box-notify-bridge-listener" ] || fail "listener missing"
[ -x "$HOME/.local/bin/ai-box-notify-bridge-uninstall" ] || fail "uninstaller missing"
[ -f "$HOME/.config/autostart/ai-box-notify-bridge-listener.desktop" ] || fail "desktop entry missing"
d="$HOME/.ai-box/notifs/out"
[ -d "$d" ] || fail "queue dir missing"
assert_eq "$(stat -c %a "$d")" "777" "queue permissions"
assert_contains "$out" "installed"
''',
"install_host.custom_bin_dir": '''setup_env
export AI_BOX_NOTIF_BIN="$TEST_DIR/custombin"
"$INSTALL_HOST" >/dev/null
[ -x "$TEST_DIR/custombin/ai-box-notify-bridge-listener" ] || fail "listener not in custom dir"
''',
"install_host.uninstall_removes_components": '''setup_env
"$INSTALL_HOST" >/dev/null
out="$("$UNINSTALL_HOST" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ ! -e "$HOME/.local/bin/ai-box-notify-bridge-listener" ] || fail "listener still present"
[ ! -e "$HOME/.local/bin/ai-box-notify-bridge-uninstall" ] || fail "uninstaller still present"
[ ! -e "$HOME/.config/autostart/ai-box-notify-bridge-listener.desktop" ] || fail "desktop entry still present"
[ ! -e "$HOME/.ai-box/notifs" ] || fail "notifs dir still present"
assert_contains "$out" "host uninstalled"
''',
"install_container.installs_shim": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
mkdir -p "$AI_BOX_NOTIF_DIR/out"
out="$("$INSTALL_CONTAINER" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ -x "$HOME/.local/bin/notify-send" ] || fail "shim missing"
[ -x "$HOME/.local/bin/ai-box-notify-bridge-uninstall" ] || fail "uninstaller missing"
assert_contains "$out" "installed"
''',
"install_container.volume_mounted_ok": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
mkdir -p "$AI_BOX_NOTIF_DIR/out"
out="$("$INSTALL_CONTAINER" 2>&1)"
assert_contains "$out" "mounted"
''',
"install_host.reinstall_uninstalls_first": '''setup_env
"$INSTALL_HOST" >/dev/null
touch "$HOME/.ai-box/notifs/old-marker"
out="$("$INSTALL_HOST" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ ! -e "$HOME/.ai-box/notifs/old-marker" ] || fail "old install not removed"
assert_contains "$out" "uninstalling first"
[ -x "$HOME/.local/bin/ai-box-notify-bridge-listener" ] || fail "listener missing after reinstall"
''',
"install_container.reinstall_uninstalls_first": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
mkdir -p "$AI_BOX_NOTIF_DIR/out"
"$INSTALL_CONTAINER" >/dev/null
out="$("$INSTALL_CONTAINER" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "uninstalling first"
[ -x "$HOME/.local/bin/notify-send" ] || fail "shim missing after reinstall"
''',
"install_container.volume_missing": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/no-such-dir"
out="$("$INSTALL_CONTAINER" 2>&1)"
assert_contains "$out" "does not exist"
''',
"install_container.volume_not_writable": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
mkdir -p "$AI_BOX_NOTIF_DIR"
chmod 555 "$AI_BOX_NOTIF_DIR"
out="$("$INSTALL_CONTAINER" 2>&1)"
if [ "$(id -u)" = "0" ]; then echo "SKIP: root bypasses permissions"; exit 0; fi
assert_contains "$out" "not writable"
''',
"install_container.path_note_added_to_rc": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
mkdir -p "$AI_BOX_NOTIF_DIR/out"
touch "$HOME/.bashrc"
out="$("$INSTALL_CONTAINER" 2>&1)"
grep -q 'Added by ai-box notify shim installer' "$HOME/.bashrc" || fail "rc not updated"
assert_contains "$out" "not in PATH"
''',
"install_container.path_already_present": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
mkdir -p "$AI_BOX_NOTIF_DIR/out"
touch "$HOME/.bashrc"
export PATH="$HOME/.local/bin:$PATH"
out="$("$INSTALL_CONTAINER" 2>&1)"
if grep -q 'Added by ai-box notify shim installer' "$HOME/.bashrc"; then fail "rc should not be modified"; fi
''',
"uninstall_container.removes_shim": '''setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
mkdir -p "$AI_BOX_NOTIF_DIR/out"
"$INSTALL_CONTAINER" >/dev/null
out="$("$UNINSTALL_CONTAINER" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ ! -e "$HOME/.local/bin/notify-send" ] || fail "shim still present"
[ ! -e "$HOME/.local/bin/ai-box-notify-bridge-uninstall" ] || fail "uninstaller still present"
assert_contains "$out" "uninstalled"
''',
}

CASES_DIR = os.path.join(HERE, 'cases')
os.makedirs(CASES_DIR, exist_ok=True)
expected = {p.replace('.', '__') + '.sh' for p, _ in LEAVES}
for old in glob.glob(os.path.join(CASES_DIR, '*.sh')):
    if os.path.basename(old) not in expected:
        os.remove(old)
        print('removed stale', old)

for path, node in LEAVES:
    expect = node.get('expect', '')
    if path in OVERRIDES:
        body = OVERRIDES[path]
    else:
        cmd = cmd_subst(node.get('command', ''))
        body = f'''setup_env
out="$({cmd} 2>&1)"; code=$?
{code_check(expect)}
{literal_checks(expect)}
'''
    script = f'''#!/usr/bin/env bash
# Case:    {path}
# Command: {node.get("command", "(see body)")}
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
