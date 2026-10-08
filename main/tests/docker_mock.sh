#!/usr/bin/env bash
# Mock docker: logs every call to $MOCK_DOCKER_LOG and tracks container
# status in $MOCK_STATE ("name:created|running|stopped", one per line).
set -u
echo "docker $*" >> "${MOCK_DOCKER_LOG:-/dev/null}"
cmd="${1:-}"; shift || true

status() {
    [ -f "$MOCK_STATE" ] || return 0
    grep -E "^$1:" "$MOCK_STATE" | head -1 | cut -d: -f2 || true
}
set_status() {
    local tmp="$MOCK_STATE.tmp"
    grep -vE "^$1:" "$MOCK_STATE" > "$tmp" 2>/dev/null || true
    echo "$1:$2" >> "$tmp"
    mv "$tmp" "$MOCK_STATE"
}
rm_status() {
    grep -vE "^$1:" "$MOCK_STATE" > "$MOCK_STATE.tmp" 2>/dev/null || true
    mv "$MOCK_STATE.tmp" "$MOCK_STATE"
}

case "$cmd" in
    create)
        name=""
        while [ $# -gt 0 ]; do
            case "$1" in
                --name)    name="$2"; shift 2 ;;
                --name=*)  name="${1#*=}"; shift ;;
                *)         shift ;;
            esac
        done
        [ -n "$name" ] || { echo "Error: missing --name" >&2; exit 1; }
        echo "$name:created" >> "$MOCK_STATE"
        ;;
    start)
        n="${1:-}"
        [ -n "$(status "$n")" ] || { echo "Error: No such container: $n" >&2; exit 1; }
        set_status "$n" running
        echo "$n"
        ;;
    stop)
        n="${1:-}"
        [ -n "$(status "$n")" ] || { echo "Error: No such container: $n" >&2; exit 1; }
        set_status "$n" stopped
        echo "$n"
        ;;
    rm)
        n=""
        for a in "$@"; do case "$a" in -*) ;; *) n="$a" ;; esac; done
        [ -n "$(status "$n")" ] || { echo "Error: No such container: $n" >&2; exit 1; }
        rm_status "$n"
        echo "$n"
        ;;
    ps)
        # Supports: docker ps -a --format '{{.Names}}'
        if [ -f "$MOCK_STATE" ]; then cut -d: -f1 "$MOCK_STATE"; fi
        ;;
    exec)
        while [ $# -gt 0 ]; do
            case "$1" in
                -u|-w) shift 2 ;;
                -*)    shift ;;
                *)     break ;;
            esac
        done
        n="${1:-}"; shift || true
        [ "$(status "$n")" = "running" ] || { echo "Error: container $n is not running" >&2; exit 1; }
        if [ "${1:-}" = "bash" ] && [ "${2:-}" = "-c" ]; then
            # Simulate the container filesystem: /work -> ~/.ai-box/work[-NAME],
            # /notifs -> ~/.ai-box/notifs (via symlinks under $SIM).
            script="$3"
            script="$(printf '%s' "$script" | sed "s|/work|$SIM/work|g; s|/notifs|$SIM/notifs|g")"
            (cd "$SIM" && bash -c "$script")
        else
            echo "FAKE_SHELL: docker exec $n $*"
        fi
        ;;
    *)
        echo "Error: mock docker does not implement '$cmd'" >&2
        exit 1
        ;;
esac
