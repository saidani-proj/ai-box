#!/usr/bin/env bash
# Shared helpers for opencode-notify-plugin test cases.
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$TESTS_DIR/.." && pwd)"
NOTIFY_JS="$ROOT/src/notify.js"
INSTALL_SH="$ROOT/src/install.sh"
UNINSTALL_SH="$ROOT/src/uninstall.sh"
BUN_BIN="$(command -v bun 2>/dev/null || echo "$HOME/.bun/bin/bun")"

setup_env() {
    export TEST_DIR="$(mktemp -d /tmp/oc-notif-test.XXXXXX)"
    export HOME="$TEST_DIR/home"
    mkdir -p "$HOME"
    export NS_LOG="$TEST_DIR/ns.log"; : > "$NS_LOG"
    mkdir -p "$TEST_DIR/bin"
    # Mock of the desktop notify-send binary.
    cat > "$TEST_DIR/bin/notify-send" <<'EOF'
#!/usr/bin/env bash
echo "NS: $*" >> "$NS_LOG"
EOF
    chmod +x "$TEST_DIR/bin/notify-send"
    # Mock of the opencode CLI (plugin install requires it in PATH).
    printf '#!/usr/bin/env bash\nexit 0\n' > "$TEST_DIR/bin/opencode"
    chmod +x "$TEST_DIR/bin/opencode"
    export PATH="$TEST_DIR/bin:$PATH"
    chmod +x "$INSTALL_SH" "$UNINSTALL_SH" 2>/dev/null || true
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
assert_log_lines() { assert_eq "$(wc -l < "$NS_LOG")" "$1" "notify-send call count"; }

# Run notify.js setup() against a scenario JSON ({directory, options, sessions,
# env, events:[...]}), one plugin instance, using a standalone Bun runtime.
run_plugin() {
    "$BUN_BIN" "$TESTS_DIR/runner.mjs" "$NOTIFY_JS" "$1"
}

cleanup() { [ -n "${TEST_DIR:-}" ] && /bin/rm -rf "$TEST_DIR"; }
trap cleanup EXIT
