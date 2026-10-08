#!/usr/bin/env bash
# Install ai-box by copying the script into ~/.local/bin.
# Usage: ./install.sh
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"

if [ $# -gt 0 ]; then
    echo "error: install.sh takes no arguments (got '$1')" >&2
    exit 1
fi

bin_dir="$HOME/.local/bin"

if ! command -v docker > /dev/null 2>&1; then
    echo "warning: docker not found in PATH; install it before using ai-box (e.g. sudo apt install docker.io)" >&2
fi

mkdir -p "$bin_dir"

if [ ! -w "$bin_dir" ]; then
    echo "error: $bin_dir is not writable" >&2
    exit 1
fi

# If ai-box is already installed in the target directory, uninstall it
# first, keeping the data (containers and ~/.ai-box).
if [ -e "$bin_dir/ai-box" ] || [ -e "$bin_dir/ai-box-uninstall" ]; then
    echo "existing ai-box installation found in $bin_dir; uninstalling (keeping data)"
    "$here/uninstall.sh" --keep-data
fi

install -m 755 "$here/ai-box.sh" "$bin_dir/ai-box"
install -m 755 "$here/uninstall.sh" "$bin_dir/ai-box-uninstall"
echo "installed ai-box to $bin_dir/ai-box"
echo "installed uninstaller to $bin_dir/ai-box-uninstall"

# Make sure the install dir is on PATH for bash, zsh and login shells.
case ":$PATH:" in
    *":$bin_dir:"*) ;;
    *)
        echo "warning: $bin_dir not in PATH" >&2
        added=0
        any_rc=0
        for rc in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile" "$HOME/.zshrc"; do
            if [ -f "$rc" ]; then
                any_rc=1
                has=0
                grep -qF "$bin_dir" "$rc" 2>/dev/null && has=1
                if [ "$bin_dir" = "$HOME/.local/bin" ] && grep -qF '$HOME/.local/bin' "$rc" 2>/dev/null; then
                    has=1
                fi
                if [ "$has" -eq 0 ]; then
                    printf '\n# Added by ai-box installer\nexport PATH="%s:$PATH"\n' "$bin_dir" >> "$rc"
                    echo "added $bin_dir to PATH in $rc"
                    added=1
                fi
            fi
        done
        case "${SHELL:-}" in
            */zsh)
                if [ ! -f "$HOME/.zshrc" ]; then
                    printf '# Added by ai-box installer\nexport PATH="%s:$PATH"\n' "$bin_dir" > "$HOME/.zshrc"
                    echo "added $bin_dir to PATH in $HOME/.zshrc"
                    added=1
                fi
                ;;
        esac
        if [ "$added" -eq 0 ] && [ "$any_rc" -eq 0 ]; then
            printf '# Added by ai-box installer\nexport PATH="%s:$PATH"\n' "$bin_dir" > "$HOME/.bashrc"
            echo "added $bin_dir to PATH in $HOME/.bashrc"
            added=1
        fi
        echo "note: run \"export PATH=$bin_dir:\$PATH\" in this shell"
        if [ "$added" -eq 1 ]; then
            echo "note: PATH was added to your shell rc files; exit the terminal and open a new one for it to take effect"
        fi
        ;;
esac
