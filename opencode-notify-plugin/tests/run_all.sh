#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")"
pass=0; failed=0
for f in cases/*.sh; do
    if timeout 30 bash "$f" > /tmp/aibox_test_out.$$ 2>&1; then
        pass=$((pass + 1)); echo "PASS $f"
    else
        failed=$((failed + 1)); echo "FAIL $f"
        head -25 /tmp/aibox_test_out.$$ | sed 's/^/    /'
    fi
done
rm -f /tmp/aibox_test_out.$$
echo "== $pass passed, $failed failed =="
[ "$failed" -eq 0 ]
