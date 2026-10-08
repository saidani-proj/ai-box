#!/usr/bin/env bash
# Uninstall ai-box by removing the scripts from ~/.local/bin.
# Usage: ./uninstall.sh [--keep-data]
set -euo pipefail

keep_data=0
for arg in "$@"; do
    case "$arg" in
        --keep-data) keep_data=1 ;;
        -h|--help)
            echo "Usage: ./uninstall.sh [--keep-data]"
            echo "  Remove ai-box and ai-box-uninstall from ~/.local/bin"
            echo "  --keep-data  Keep containers ai-box* and ~/.ai-box (no prompt)"
            exit 0
            ;;
        *)
            echo "error: unknown option '$arg' (expected --keep-data)" >&2
            exit 1
            ;;
    esac
done

bin_dir="$HOME/.local/bin"

rm -f "$bin_dir/ai-box" "$bin_dir/ai-box-uninstall"
echo "removed ai-box from $bin_dir"

# Offer to remove ai-box data: ai-box* containers and ~/.ai-box.
containers=""
if command -v docker > /dev/null 2>&1; then
    containers="$(docker ps -a --format '{{.Names}}' 2>/dev/null | grep -E '^ai-box(-|$)' || true)"
fi

if [ -n "$containers" ] || [ -e "$HOME/.ai-box" ]; then
    if [ "$keep_data" -eq 1 ]; then
        echo "ai-box data kept (--keep-data)"
        exit 0
    fi
    echo "Found ai-box data:"
    [ -n "$containers" ] && printf '  containers: %s\n' "$(echo "$containers" | tr '\n' ' ')"
    [ -e "$HOME/.ai-box" ] && echo "  directory: $HOME/.ai-box"
    printf 'Delete this data? [y/N] '
    read -r reply || reply=""
    case "$reply" in
        y|Y|yes|YES)
            for c in $containers; do docker rm -f "$c" > /dev/null 2>&1 || true; done
            rm -rf "$HOME/.ai-box"
            echo "ai-box data removed"
            ;;
        *)
            echo "ai-box data kept"
            ;;
    esac
fi
