#!/bin/sh
# ================================
# listener (host side)
# ================================
set -u

BRIDGE_DIR="${AI_BOX_NOTIF_DIR:-$HOME/.ai-box/notifs}"
QUEUE_DIR="$BRIDGE_DIR/out"
LOCK="$BRIDGE_DIR/ai-box-notify-bridge-listener.lock"

SEND="${AI_BOX_NOTIF_SEND:-notify-send}"

INTERVAL=1
ONCE=0

STALE_IN="${AI_BOX_NOTIF_STALE:-60}"
case $STALE_IN in
'' | *[!0-9]*) STALE_IN=60 ;;
esac

die() {
	printf '%s: %s\n' "${0##*/}" "$*" >&2
	exit 1
}

usage() {
	cat <<'EOF'
Usage: ai-box-notify-bridge-listener [--once] [--interval SECONDS] [--version]
Environment: AI_BOX_NOTIF_DIR, AI_BOX_NOTIF_SEND, AI_BOX_NOTIF_STALE
EOF
}

ub64() {
	[ -n "$1" ] || return 0
	printf '%s' "$1" | base64 -d 2>/dev/null
}

sweep_stale() {
	[ "$STALE_IN" -gt 0 ] || return 0
	now=$(date +%s 2>/dev/null) || return 0
	case $now in '' | *[!0-9]*) return 0 ;; esac
	for t in "$QUEUE_DIR"/.in.*; do
		[ -e "$t" ] || continue
		m=$(stat -c %Y "$t" 2>/dev/null) || continue
		case $m in '' | *[!0-9]*) continue ;; esac
		[ "$((now - m))" -ge "$STALE_IN" ] || continue
		rm -f "$t" 2>/dev/null || continue
	done
	return 0
}

process() {
	f=$1
	base=${f##*/}; mid=${base#msg-}; mid=${mid%.msg}
	urgency='' app='' icon='' expire='' title='' hints=''
	[ -e "$f" ] || return 0
	exec 8<"$f" || { rm -f "$f"; return 1; }
	if ! IFS= read -r magic <&8 || [ "$magic" != 'AN1' ]; then
		exec 8<&-; rm -f "$f"; return 1
	fi
	complete=0
	while IFS= read -r line <&8; do
		case $line in
		AN1) ;;
		U=*) urgency=$(ub64 "${line#U=}") ;;
		A=*) app=$(ub64 "${line#A=}") ;;
		I=*) icon=$(ub64 "${line#I=}") ;;
		X=*) expire=${line#X=} ;;
		h=*) hints="$hints${line#h=}
" ;;
		T=*) title=$(ub64 "${line#T=}") ;;
		B=*) complete=1; break ;;
		esac
	done
	if [ "$complete" -ne 1 ]; then
		exec 8<&-; rm -f "$f"; return 1
	fi
	body=$(cat <&8 2>/dev/null); exec 8<&-
	set --
	[ -n "$app" ] && set -- "$@" -a "$app"
	[ -n "$icon" ] && set -- "$@" -i "$icon"
	case $urgency in low | normal | critical) set -- "$@" -u "$urgency" ;; esac
	case $expire in '' | *[!0-9]*) ;; *) set -- "$@" -t "$expire" ;; esac
	for hb in $hints; do set -- "$@" --hint="$(ub64 "$hb")"; done
	set -- "$@" "$title" "$body"
	"$SEND" -p "$@" >/dev/null 2>&1
	rm -f "$f"
}

drain() {
	for f in "$QUEUE_DIR"/msg-*.msg; do [ -e "$f" ] || continue; process "$f"; done
	sweep_stale
}

cleanup() { exit 0; }

while [ $# -gt 0 ]; do
	case $1 in
	--once) ONCE=1 ;;
	--interval) shift; INTERVAL=${1:-1} ;;
	--version) printf '1.0.0\n'; exit 0 ;;
	--help | -\?) usage; exit 0 ;;
	*) printf '%s: unknown option: %s\n' "${0##*/}" "$1" >&2; exit 1 ;;
	esac
	shift
done
case $INTERVAL in '' | *[!0-9]*) INTERVAL=1 ;; esac

command -v "$SEND" >/dev/null 2>&1 || die "notify-send not found in PATH: $SEND"
case $("$SEND" --version 2>&1) in *notify-bridge*) die "notify-send in PATH is the notify-bridge shim" ;; esac

case $BRIDGE_DIR in
/*) [ "$BRIDGE_DIR" != / ] || die "AI_BOX_NOTIF_DIR too short" ;;
*) die "AI_BOX_NOTIF_DIR must be absolute" ;;
esac

exec 7>"$LOCK" || die "lock unavailable"; flock -n 7 || exit 0
mkdir -p "$QUEUE_DIR" 2>/dev/null; chmod 0777 "$QUEUE_DIR" 2>/dev/null
[ -d "$QUEUE_DIR" ] || die "queue missing"; [ -w "$QUEUE_DIR" ] || die "queue not writable"
trap cleanup TERM INT HUP
if [ "$ONCE" = 1 ]; then drain; exit 0; fi
# Daemon mode: a (re)start resets the queue, it does not drain it.
rm -rf "$QUEUE_DIR" "$BRIDGE_DIR/idmap" "$BRIDGE_DIR/seq" "$BRIDGE_DIR/seq.lock" 2>/dev/null || :
mkdir -p "$QUEUE_DIR" 2>/dev/null; chmod 0777 "$QUEUE_DIR" 2>/dev/null
while :; do drain; sleep "$INTERVAL"; done
