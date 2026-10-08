#!/usr/bin/env bash
# Shared helpers for notify-bridge test cases.
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$TESTS_DIR/.." && pwd)"
SHIM="$ROOT/src/notify-send-shim.sh"
LISTENER="$ROOT/src/listener.sh"
INSTALL_HOST="$ROOT/src/install-host.sh"
UNINSTALL_HOST="$ROOT/src/uninstall-host.sh"
INSTALL_CONTAINER="$ROOT/src/install-container.sh"
UNINSTALL_CONTAINER="$ROOT/src/uninstall-container.sh"

setup_env() {
    export TEST_DIR="$(mktemp -d /tmp/aibox-notif-test.XXXXXX)"
    export HOME="$TEST_DIR/home"
    mkdir -p "$HOME"
    export NS_LOG="$TEST_DIR/ns.log"; : > "$NS_LOG"
    mkdir -p "$TEST_DIR/bin"
    # Mock of the host desktop notify-send.
    cat > "$TEST_DIR/bin/notify-send" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "--version" ]; then echo "notify-send 3.0 (mock)"; exit 0; fi
echo "NS: $*" >> "$NS_LOG"
EOF
    chmod +x "$TEST_DIR/bin/notify-send"
    export PATH="$TEST_DIR/bin:$PATH"
    chmod +x "$SHIM" "$LISTENER" "$INSTALL_HOST" "$UNINSTALL_HOST" \
            "$INSTALL_CONTAINER" "$UNINSTALL_CONTAINER" 2>/dev/null || true
    cd "$TEST_DIR" || exit 1
}

fail() { echo "FAIL: $*" >&2; exit 1; }
assert_eq() { [ "$1" = "$2" ] || fail "expected '$2', got '$1' ($3)"; }
assert_contains() {
    case "$1" in
        *"$2"*) ;;
        *) echo "--- output ---"; printf '%s\n' "$1"; fail "expected output to contain: $2" ;;
    esac
}
assert_log_contains() { assert_contains "$(cat "$NS_LOG")" "$1"; }

cleanup() { [ -n "${TEST_DIR:-}" ] && /bin/rm -rf "$TEST_DIR"; }
trap cleanup EXIT
