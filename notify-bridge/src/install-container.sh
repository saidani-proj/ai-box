#!/bin/sh
# notify-bridge install script (container side)
# Usage: ./install-container.sh
set -eu

HERE=$(cd -- "$(dirname -- "$0")" && pwd)
BIN_DIR="${AI_BOX_NOTIF_BIN:-$HOME/.local/bin}"
CONT_DIR="${AI_BOX_NOTIF_DIR:-/notifs}"
QUEUE_CONT="$CONT_DIR/out"

if [ -e "$BIN_DIR/notify-send" ] || [ -e "$BIN_DIR/ai-box-notify-bridge-uninstall" ]; then
	printf 'existing installation detected, uninstalling first\n'
	"$HERE/uninstall-container.sh"
fi

mkdir -p "$BIN_DIR"
install -m 0755 "$HERE/notify-send-shim.sh" "$BIN_DIR/notify-send"
install -m 0755 "$HERE/uninstall-container.sh" "$BIN_DIR/ai-box-notify-bridge-uninstall"

printf 'installed : %s\n' "$BIN_DIR/notify-send"
printf 'installed : %s\n' "$BIN_DIR/ai-box-notify-bridge-uninstall"
printf 'queue     : %s\n' "$QUEUE_CONT"

if [ -d "$QUEUE_CONT" ] && [ -w "$QUEUE_CONT" ]; then
	printf 'volume    : %s (mounted)\n' "$CONT_DIR"
elif [ -d "$CONT_DIR" ]; then
	printf '\n  [KO] %s not writable by uid %s\n' "$CONT_DIR" "$(id -u)"
else
	printf '\n  [KO] %s does not exist (not mounted)\n' "$CONT_DIR"
fi
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
	printf '\n  [warn] %s not in PATH\n' "$BIN_DIR"
	added=0
	any_rc=0
	for rc in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.bash_login" "$HOME/.profile" "$HOME/.zshrc"; do
		if [ -f "$rc" ]; then
			any_rc=1
			has=0
			grep -qF "$BIN_DIR" "$rc" 2>/dev/null && has=1
			if [ "$BIN_DIR" = "$HOME/.local/bin" ] && grep -qF '$HOME/.local/bin' "$rc" 2>/dev/null; then
				has=1
			fi
			if [ "$has" -eq 0 ]; then
				printf '\n# Added by ai-box notify shim installer\nexport PATH="%s:$PATH"\n' "$BIN_DIR" >> "$rc"
				printf '  added %s to PATH in %s\n' "$BIN_DIR" "$rc"
				added=1
			fi
		fi
	done
	case "${SHELL:-}" in
	*/zsh)
		if [ ! -f "$HOME/.zshrc" ]; then
			printf '# Added by ai-box notify shim installer\nexport PATH="%s:$PATH"\n' "$BIN_DIR" > "$HOME/.zshrc"
			printf '  added %s to PATH in %s\n' "$BIN_DIR" "$HOME/.zshrc"
			added=1
		fi
		;;
	esac
	if [ "$added" -eq 0 ] && [ "$any_rc" -eq 0 ]; then
		printf '# Added by ai-box notify shim installer\nexport PATH="%s:$PATH"\n' "$BIN_DIR" > "$HOME/.bashrc"
		printf '  added %s to PATH in %s\n' "$BIN_DIR" "$HOME/.bashrc"
		added=1
	fi
	printf '  note: run "export PATH=%s:$PATH" in this shell\n' "$BIN_DIR"
	if [ "$added" -eq 1 ]; then
		printf '  note: PATH was added to your shell rc files; exit the terminal and open a new one for it to take effect\n'
	fi
	;;
esac
cat <<'EOF'

Next steps
  1. Test: notify-send "notify-bridge" "hello"
EOF
