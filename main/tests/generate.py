#!/usr/bin/env python3
"""Generate one test script per leaf case in CASES.yaml."""
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

def cmd_subst(c):
    c = re.sub(r'(?<!/)\bai-box\b(?!-)', '"$AI_BOX"', c)
    c = c.replace('./install.sh', '"$INSTALL_SH"').replace('./uninstall.sh', '"$UNINSTALL_SH"')
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

# Bodies that override the generic template. Each must start with setup_env
# (or export DOCKER_ABSENT=1 before setup_env).
OVERRIDES = {
"install.default": '''setup_env
out="$("$AI_BOX" install 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_log_contains "--add-host=host.docker.internal:host-gateway"
assert_log_contains "--name ai-box"
assert_log_contains "ubuntu:26.04"
assert_log_contains ".ai-box/notifs:/notifs"
assert_log_contains ".ai-box/work:/work"
''',
"install.with_id": '''setup_env
out="$("$AI_BOX" install --id test 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_log_contains "--name ai-box-test"
''',
"install.id_equals": '''setup_env
out="$("$AI_BOX" install --id=test 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_log_contains "--name ai-box-test"
''',
"install.disable_net": '''setup_env
out="$("$AI_BOX" install --disable-net 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
if grep -q -- '--add-host' "$MOCK_DOCKER_LOG"; then fail "--add-host should be omitted with --disable-net"; fi
''',
"install.disable_notifs": '''setup_env
out="$("$AI_BOX" install --disable-notifs 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
if grep -q 'notifs:/notifs' "$MOCK_DOCKER_LOG"; then fail "notifs volume should be omitted with --disable-notifs"; fi
''',
"install.create_opts_passthrough": '''setup_env
out="$("$AI_BOX" install -- --cpus 2 -e FOO=bar 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_log_contains "--cpus 2"
assert_log_contains "-e FOO=bar"
''',
"install.docker_missing": '''export DOCKER_ABSENT=1
setup_env
out="$("$AI_BOX" install 2>&1)"; code=$?
[ "$code" -ne 0 ] || fail "expected non-zero exit code"
''',
"up.nominal": '''setup_env
"$AI_BOX" install >/dev/null
hostdir="$TEST_DIR/proj"; mkdir -p "$hostdir"
out="$(cd "$hostdir" && "$AI_BOX" up 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_eq "$(readlink "$HOME/.ai-box/work")" "$hostdir" "workdir symlink"
assert_log_contains "-u $(id -u):$(id -g)"
assert_log_contains "-w /work"
grep -q '^ai-box:running' "$MOCK_STATE" || fail "container not running"
''',
"up.from_inside_ai_box_work": '''setup_env
mkdir -p "$HOME/.ai-box/work"
out="$(cd "$HOME/.ai-box/work" && "$AI_BOX" up 2>&1)"; code=$?
assert_eq "$code" "1" "exit code"
assert_contains "$out" "is inside ~/.ai-box/work"
[ ! -L "$HOME/.ai-box/work" ] || fail "symlink created unexpectedly"
''',
"up.notifs_dir_created": '''setup_env
"$AI_BOX" install >/dev/null
p="$TEST_DIR/p"; mkdir -p "$p"
(cd "$p" && "$AI_BOX" up >/dev/null 2>&1)
[ -d "$HOME/.ai-box/notifs" ] || fail "notifs dir not created"
''',
"up.symlink_updated": '''setup_env
"$AI_BOX" install >/dev/null
a="$TEST_DIR/a"; b="$TEST_DIR/b"; mkdir -p "$a" "$b"
(cd "$a" && "$AI_BOX" up >/dev/null 2>&1)
assert_eq "$(readlink "$HOME/.ai-box/work")" "$a" "symlink should point to a"
(cd "$b" && "$AI_BOX" up >/dev/null 2>&1)
assert_eq "$(readlink "$HOME/.ai-box/work")" "$b" "symlink should point to b"
''',
"down.nominal": '''setup_env
"$AI_BOX" install >/dev/null
out="$("$AI_BOX" down 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
grep -q '^ai-box:stopped' "$MOCK_STATE" || fail "container not stopped"
''',
"exe.nominal": '''setup_env
seed_container ai-box running
p="$TEST_DIR/p"; mkdir -p "$p"
ln -s "$p" "$HOME/.ai-box/work"
before="$(readlink "$HOME/.ai-box/work")"
out="$("$AI_BOX" exe 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "FAKE_SHELL"
assert_log_contains "-u $(id -u):$(id -g)"
assert_log_contains "-w /work"
after="$(readlink "$HOME/.ai-box/work")"
assert_eq "$after" "$before" "symlink must not change"
''',
"root.nominal": '''setup_env
seed_container ai-box running
out="$("$AI_BOX" root 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "FAKE_SHELL"
assert_log_contains "docker exec -it ai-box bash"
if grep -q -- '-u' "$MOCK_DOCKER_LOG"; then fail "root should not pass -u"; fi
''',
"uninstall.nominal": '''setup_env
"$AI_BOX" install >/dev/null
p="$TEST_DIR/p"; mkdir -p "$p"
(cd "$p" && "$AI_BOX" up >/dev/null 2>&1)
out="$("$AI_BOX" uninstall 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ ! -L "$HOME/.ai-box/work" ] || fail "work symlink should be removed"
[ -d "$HOME/.ai-box" ] || fail "~/.ai-box should be kept"
if grep -q 'ai-box' "$MOCK_STATE"; then fail "container should be removed"; fi
''',
"uninstall.named_id": '''setup_env
"$AI_BOX" install --id test >/dev/null
p="$TEST_DIR/p"; mkdir -p "$p"
(cd "$p" && "$AI_BOX" up --id test >/dev/null 2>&1)
out="$("$AI_BOX" uninstall --id test 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
if grep -q '^ai-box-test:' "$MOCK_STATE"; then fail "ai-box-test should be removed"; fi
[ ! -L "$HOME/.ai-box/work-test" ] || fail "work-test symlink should be removed"
[ -d "$HOME/.ai-box" ] || fail "~/.ai-box should be kept"
''',
"named_id.isolate_containers": '''setup_env
"$AI_BOX" install --id a >/dev/null
"$AI_BOX" install --id b >/dev/null
p1="$TEST_DIR/p1"; p2="$TEST_DIR/p2"; mkdir -p "$p1" "$p2"
(cd "$p1" && "$AI_BOX" up --id a >/dev/null 2>&1)
assert_log_contains "docker exec -it -u $(id -u):$(id -g) -w /work ai-box-a bash"
(cd "$p2" && "$AI_BOX" up --id b >/dev/null 2>&1)
assert_log_contains "docker exec -it -u $(id -u):$(id -g) -w /work ai-box-b bash"
c=$(grep -c 'ai-box-a bash' "$MOCK_DOCKER_LOG")
assert_eq "$c" "1" "ai-box-a exec count"
''',
"named_id.full_cycle": '''setup_env
"$AI_BOX" install --id x >/dev/null
p="$TEST_DIR/p"; mkdir -p "$p"
(cd "$p" && "$AI_BOX" up --id x >/dev/null 2>&1)
"$AI_BOX" down --id x >/dev/null
out="$("$AI_BOX" uninstall --id x 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ -d "$HOME/.ai-box" ] || fail "~/.ai-box should be kept"
[ ! -L "$HOME/.ai-box/work-x" ] || fail "work-x symlink should be removed"
if grep -q 'ai-box-x' "$MOCK_STATE"; then fail "ai-box-x should be removed"; fi
''',
"named_id.work_dir_per_id": '''setup_env
"$AI_BOX" install --id test >/dev/null
assert_log_contains ".ai-box/work-test:/work"
p="$TEST_DIR/p"; mkdir -p "$p"
(cd "$p" && "$AI_BOX" up --id test >/dev/null 2>&1)
assert_eq "$(readlink "$HOME/.ai-box/work-test")" "$p" "work-test symlink"
[ ! -L "$HOME/.ai-box/work" ] || fail "default work symlink should not be created"
''',
"install_uninstall_scripts.install_default_user": '''setup_env
out="$("$INSTALL_SH" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ -x "$HOME/.local/bin/ai-box" ] || fail "ai-box not installed"
[ -x "$HOME/.local/bin/ai-box-uninstall" ] || fail "ai-box-uninstall not installed"
assert_contains "$out" "installed ai-box to"
''',
"install_uninstall_scripts.install_bin_not_writable": '''setup_env
mkdir -p "$HOME/.local/bin"
chmod 555 "$HOME/.local/bin"
out="$("$INSTALL_SH" 2>&1)"; code=$?
if [ "$(id -u)" = "0" ]; then
    echo "SKIP: root bypasses permission bits"
    exit 0
fi
assert_eq "$code" "1" "exit code"
assert_contains "$out" "not writable"
''',
"install_uninstall_scripts.install_docker_missing": '''export DOCKER_ABSENT=1
setup_env
out="$("$INSTALL_SH" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "docker not found"
[ -x "$HOME/.local/bin/ai-box" ] || fail "ai-box should still be installed"
''',
"install_uninstall_scripts.uninstall_default_user": '''setup_env
"$INSTALL_SH" >/dev/null
out="$("$UNINSTALL_SH" </dev/null 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
[ ! -e "$HOME/.local/bin/ai-box" ] || fail "ai-box should be removed"
[ ! -e "$HOME/.local/bin/ai-box-uninstall" ] || fail "ai-box-uninstall should be removed"
''',
"install_uninstall_scripts.roundtrip": '''setup_env
"$INSTALL_SH" >/dev/null
[ -x "$HOME/.local/bin/ai-box" ] || fail "ai-box not installed"
out="$("$UNINSTALL_SH" </dev/null 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "removed ai-box"
[ ! -e "$HOME/.local/bin/ai-box" ] || fail "ai-box should be removed"
[ ! -e "$HOME/.local/bin/ai-box-uninstall" ] || fail "ai-box-uninstall should be removed"
''',
"install_uninstall_scripts.installed_version": '''setup_env
"$INSTALL_SH" >/dev/null
out="$("$HOME/.local/bin/ai-box" --version 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "1.0.0"
''',
"install_uninstall_scripts.uninstall_idempotent": '''setup_env
out="$("$UNINSTALL_SH" </dev/null 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "removed ai-box"
''',
"install_uninstall_scripts.uninstall_confirm_yes": '''setup_env
"$AI_BOX" install >/dev/null
grep -q '^ai-box:' "$MOCK_STATE" || fail "container not created"
out="$(printf 'y\\n' | "$UNINSTALL_SH" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "Delete this data?"
assert_contains "$out" "ai-box data removed"
if grep -q '^ai-box' "$MOCK_STATE"; then fail "container should be removed"; fi
[ ! -e "$HOME/.ai-box" ] || fail "~/.ai-box should be removed"
''',
"install_uninstall_scripts.uninstall_confirm_no": '''setup_env
"$AI_BOX" install >/dev/null
out="$(printf 'n\\n' | "$UNINSTALL_SH" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "ai-box data kept"
grep -q '^ai-box:' "$MOCK_STATE" || fail "container should be kept"
[ -e "$HOME/.ai-box" ] || fail "~/.ai-box should be kept"
''',
"install_uninstall_scripts.reinstall_keeps_data": '''setup_env
"$INSTALL_SH" >/dev/null
"$AI_BOX" install >/dev/null
out="$("$INSTALL_SH" </dev/null 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "existing ai-box installation"
assert_contains "$out" "installed ai-box to"
grep -q '^ai-box:' "$MOCK_STATE" || fail "container should be kept"
[ -e "$HOME/.ai-box" ] || fail "~/.ai-box should be kept"
[ -x "$HOME/.local/bin/ai-box" ] || fail "ai-box should be reinstalled"
''',
"install_uninstall_scripts.uninstall_keep_data": '''setup_env
"$AI_BOX" install >/dev/null
out="$("$UNINSTALL_SH" --keep-data </dev/null 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "ai-box data kept (--keep-data)"
case "$out" in
    *"Delete this data?"*) fail "should not prompt with --keep-data" ;;
esac
grep -q '^ai-box:' "$MOCK_STATE" || fail "container should be kept"
[ -e "$HOME/.ai-box" ] || fail "~/.ai-box should be kept"
''',
"install_uninstall_scripts.uninstall_no_data": '''setup_env
rm -rf "$HOME/.ai-box"
out="$("$UNINSTALL_SH" </dev/null 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
case "$out" in
    *"Delete this data?"*) fail "should not prompt when no data exists" ;;
esac
''',
"shared_mounts.edit_host_files_from_box": '''setup_env
"$AI_BOX" install >/dev/null
hostdir="$TEST_DIR/proj"; mkdir -p "$hostdir"
(cd "$hostdir" && "$AI_BOX" up >/dev/null 2>&1)
docker exec ai-box bash -c 'echo box-content > /work/from_box.txt'
[ -f "$hostdir/from_box.txt" ] || fail "file created in box not visible on host"
assert_contains "$(cat "$hostdir/from_box.txt")" "box-content"
''',
"shared_mounts.notifs_shared": '''setup_env
"$AI_BOX" install >/dev/null
p="$TEST_DIR/p"; mkdir -p "$p"
(cd "$p" && "$AI_BOX" up >/dev/null 2>&1)
docker exec ai-box bash -c 'echo note > /notifs/note.txt'
[ -f "$HOME/.ai-box/notifs/note.txt" ] || fail "file written in box not visible on host"
assert_contains "$(cat "$HOME/.ai-box/notifs/note.txt")" "note"
''',
}

import glob

CASES_DIR = os.path.join(HERE, 'cases')
os.makedirs(CASES_DIR, exist_ok=True)

# Remove scripts whose case no longer exists in CASES.yaml (stale files).
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
# Case:   {path}
# Command: {node.get("command", "(see body)")}
# Context: {node.get("context", "")}
# Expect:  {expect}
set -uo pipefail
source "{os.path.join(HERE, 'lib.sh')}"
{body}
echo "ok: {path}"
'''
    fname = path.replace('.', '__') + '.sh'
    fpath = os.path.join(HERE, 'cases', fname)
    with open(fpath, 'w') as f:
        f.write(script)
    os.chmod(fpath, os.stat(fpath).st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    print('wrote', fpath)
