#!/usr/bin/env bash
# Shared helpers for ai-box test cases.
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_BOX="$(cd "$TESTS_DIR/.." && pwd)/src/ai-box.sh"
INSTALL_SH="$(cd "$TESTS_DIR/.." && pwd)/src/install.sh"
UNINSTALL_SH="$(cd "$TESTS_DIR/.." && pwd)/src/uninstall.sh"

setup_env() {
    export TEST_DIR="$(mktemp -d /tmp/aibox-test.XXXXXX)"
    export HOME="$TEST_DIR/home"
    mkdir -p "$HOME/.ai-box"
    export MOCK_STATE="$TEST_DIR/state"; : > "$MOCK_STATE"
    export MOCK_DOCKER_LOG="$TEST_DIR/docker.log"; : > "$MOCK_DOCKER_LOG"
    export SIM="$TEST_DIR/sim"; mkdir -p "$SIM"
    ln -sfn "$HOME/.ai-box/work" "$SIM/work"
    ln -sfn "$HOME/.ai-box/notifs" "$SIM/notifs"
    mkdir -p "$TEST_DIR/bin"
    if [ -z "${DOCKER_ABSENT:-}" ]; then
        cp "$TESTS_DIR/docker_mock.sh" "$TEST_DIR/bin/docker"
        chmod +x "$TEST_DIR/bin/docker"
    fi
    export PATH="$TEST_DIR/bin:$PATH"
    chmod +x "$AI_BOX" "$INSTALL_SH" "$UNINSTALL_SH" 2>/dev/null || true
    cd "$TEST_DIR" || exit 1
}

seed_container() { echo "$1:$2" >> "$MOCK_STATE"; }

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_eq() { [ "$1" = "$2" ] || fail "expected '$2', got '$1' ($3)"; }
assert_contains() {
    case "$1" in
        *"$2"*) ;;
        *) echo "--- output ---"; printf '%s\n' "$1"; fail "expected output to contain: $2" ;;
    esac
}
assert_log_contains() { assert_contains "$(cat "$MOCK_DOCKER_LOG")" "$1"; }

cleanup() { [ -n "${TEST_DIR:-}" ] && /bin/rm -rf "$TEST_DIR"; }
trap cleanup EXIT
