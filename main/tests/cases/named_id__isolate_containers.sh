#!/usr/bin/env bash
# Case:   named_id.isolate_containers
# Command: (see body)
# Context: two boxes with different --id
# Expect:  each command targets its own container
set -uo pipefail
source "/work/main/tests/lib.sh"
setup_env
"$AI_BOX" install --id a >/dev/null
"$AI_BOX" install --id b >/dev/null
p1="$TEST_DIR/p1"; p2="$TEST_DIR/p2"; mkdir -p "$p1" "$p2"
(cd "$p1" && "$AI_BOX" up --id a >/dev/null 2>&1)
assert_log_contains "docker exec -it -u $(id -u):$(id -g) -w /work ai-box-a bash"
(cd "$p2" && "$AI_BOX" up --id b >/dev/null 2>&1)
assert_log_contains "docker exec -it -u $(id -u):$(id -g) -w /work ai-box-b bash"
c=$(grep -c 'ai-box-a bash' "$MOCK_DOCKER_LOG")
assert_eq "$c" "1" "ai-box-a exec count"

echo "ok: named_id.isolate_containers"
