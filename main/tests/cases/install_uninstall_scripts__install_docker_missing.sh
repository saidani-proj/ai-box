#!/usr/bin/env bash
# Case:   install_uninstall_scripts.install_docker_missing
# Command: ./install.sh
# Context: docker missing from PATH
# Expect:  warning "docker not found" but install still succeeds
set -uo pipefail
source "/work/main/tests/lib.sh"
export DOCKER_ABSENT=1
setup_env
out="$("$INSTALL_SH" 2>&1)"; code=$?
assert_eq "$code" "0" "exit code"
assert_contains "$out" "docker not found"
[ -x "$HOME/.local/bin/ai-box" ] || fail "ai-box should still be installed"

echo "ok: install_uninstall_scripts.install_docker_missing"
