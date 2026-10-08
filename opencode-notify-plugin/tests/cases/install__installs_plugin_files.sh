#!/usr/bin/env bash
# Case:    install.installs_plugin_files
# Expect:  index.js, package.json, opencode.json installed
set -uo pipefail
source "/work/opencode-notify-plugin/tests/lib.sh"
setup_env
"$INSTALL_SH" >/dev/null
p="$HOME/.config/opencode/plugins/ai-box-notify"
[ -f "$p/index.js" ] || fail "index.js missing"
[ -f "$p/package.json" ] || fail "package.json missing"
[ -f "$p/opencode.json" ] || fail "opencode.json missing"
python3 -c "import json;d=json.load(open('$p/package.json'));assert d['type']=='module'"

echo "ok: install.installs_plugin_files"
