#!/bin/sh
# notify-bridge install script (host side)
# Usage: ./install-host.sh
set -eu

HERE=$(cd -- "$(dirname -- "$0")" && pwd)
BIN_DIR="${AI_BOX_NOTIF_BIN:-$HOME/.local/bin}"
AUTOSTART_DIR="$HOME/.config/autostart"
HOST_DIR="${AI_BOX_NOTIF_DIR:-$HOME/.ai-box/notifs}"
QUEUE_HOST="$HOST_DIR/out"

if [ -e "$BIN_DIR/ai-box-notify-bridge-listener" ] || [ -e "$BIN_DIR/ai-box-notify-bridge-uninstall" ] || [ -e "$AUTOSTART_DIR/ai-box-notify-bridge-listener.desktop" ] || [ -d "$HOST_DIR" ]; then
	printf 'existing installation detected, uninstalling first\n'
	"$HERE/uninstall-host.sh"
fi

mkdir -p "$BIN_DIR" "$AUTOSTART_DIR" "$QUEUE_HOST"
chmod 0777 "$QUEUE_HOST" 2>/dev/null || true

install -m 0755 "$HERE/listener.sh" "$BIN_DIR/ai-box-notify-bridge-listener"
install -m 0755 "$HERE/uninstall-host.sh" "$BIN_DIR/ai-box-notify-bridge-uninstall"

cat >"$AUTOSTART_DIR/ai-box-notify-bridge-listener.desktop" <<EOF
[Desktop Entry]
Type=Application
Version=1.0.0
Name=AI box notifications (listener)
Comment=Forwards the notify-bridge queue to notify-send
Exec=$BIN_DIR/ai-box-notify-bridge-listener
Terminal=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
EOF

printf 'installed : %s\n' "$BIN_DIR/ai-box-notify-bridge-listener"
printf 'installed : %s\n' "$BIN_DIR/ai-box-notify-bridge-uninstall"
printf 'autostart : %s\n' "$AUTOSTART_DIR/ai-box-notify-bridge-listener.desktop"
printf 'queue     : %s\n' "$QUEUE_HOST"
cat <<EOF

Next steps
  1. Mount this directory in the container: -v $HOST_DIR:/notifs
  2. Run ./install-container.sh inside the container
  3. Log out and back in (or start listener manually)
EOF

# Make sure BIN_DIR is on PATH for bash, zsh and login shells.
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
