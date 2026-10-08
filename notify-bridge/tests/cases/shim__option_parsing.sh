#!/usr/bin/env bash
# Case:    shim.option_parsing
# Command: notify-send-shim.sh -u critical -a MyApp -i myicon -t 5000 "t" "b"
# Expect:  "U=", "A=", "I=", "X=" set accordingly
set -uo pipefail
source "/work/notify-bridge/tests/lib.sh"
setup_env
export AI_BOX_NOTIF_DIR="$TEST_DIR/notifs"
"$SHIM" -u critical -a MyApp -i myicon -t 5000 "t" "b"
f=$(ls "$AI_BOX_NOTIF_DIR/out"/msg-*.msg)
check() { local line="$1" want="$2"; local v; v=$(grep "^$line=" "$f" | cut -d= -f2- | base64 -d); assert_eq "$v" "$want" "field $line"; }
check U critical
check A MyApp
check I myicon
v=$(grep '^X=' "$f" | cut -d= -f2-); assert_eq "$v" "5000" "field X"

echo "ok: shim.option_parsing"
