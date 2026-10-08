#!/bin/sh
# ================================
# notify-send shim (container side)
# ================================
set -u

BRIDGE_DIR="${AI_BOX_NOTIF_DIR:-/notifs}"
QUEUE_DIR="$BRIDGE_DIR/out"
SEQ="$BRIDGE_DIR/seq"
SEQ_LOCK="$BRIDGE_DIR/seq.lock"

MAX_QUEUE="${AI_BOX_NOTIF_MAX:-100}"
VERSION='notify-send (notify-bridge) 3.0.0'

die() { printf '%s: %s\n' "${0##*/}" "$*" >&2; exit 1; }

usage() {
	cat <<'EOF'
Usage: notify-send [OPTION...] SUMMARY [BODY]
EOF
}

b64() { printf '%s' "$1" | base64 | tr -d '\n'; }

trim() {
	case $MAX_QUEUE in '' | *[!0-9]*) return 0 ;; 0) return 0 ;; esac
	set -- "$QUEUE_DIR"/msg-*.msg; [ -e "$1" ] || return 0
	drop=$(( $# - MAX_QUEUE )); [ "$drop" -gt 0 ] || return 0
	i=1; while [ "$i" -le "$drop" ]; do rm -f "$1"; shift; i=$((i+1)); done
	[ "${AI_BOX_NOTIF_VERBOSE:-0}" = 1 ] && printf '%s: queue full, %s dropped\n' "${0##*/}" "$drop" >&2
	return 0
}

next_id() {
	exec 9>"$SEQ_LOCK" || return 1
	flock -x 9 || { exec 9>&-; return 1; }
	n=$(cat "$SEQ" 2>/dev/null || printf '0'); case $n in '' | *[!0-9]*) n=0 ;; esac
	n=$((n+1)); printf '%s\n' "$n" >"$SEQ"; exec 9>&-; printf '%s' "$n"
}

urgency='normal'; app=''; icon=''; expire=''; replace=''; hints=''; print_id=0
while [ $# -gt 0 ]; do
	case $1 in
	-u|--urgency) shift; urgency=${1:-normal} ;;
	--urgency=*) urgency=${1#*=} ;; -u?*) urgency=${1#-u} ;;
	-i|--icon) shift; icon=${1:-} ;; --icon=*) icon=${1#*=} ;; -i?*) icon=${1#-i} ;;
	-a|--app-name) shift; app=${1:-} ;; --app-name=*) app=${1#*=} ;; -a?*) app=${1#-a} ;;
	-t|--expire-time) shift; expire=${1:-} ;; --expire-time=*) expire=${1#*=} ;; -t?*) expire=${1#-t} ;;
	-r|--replace-id) shift; replace=${1:-} ;; --replace-id=*) replace=${1#*=} ;; -r?*) replace=${1#-r} ;;
	-h|--hint) shift; hints="$hints$(b64 "${1:-}")
" ;; --hint=*) hints="$hints$(b64 "${1#*=}")
" ;;
	-p|--print-id) print_id=1 ;;
	-v|--version) printf '%s\n' "$VERSION"; exit 0 ;;
	--help|-h|-\?) usage; exit 0 ;;
	--) shift; break ;;
	-*) die "unknown option: $1" ;;
	*) break ;;
	esac
	shift
done
title=${1:-}; body=${2:-}
case $urgency in low|normal|critical) ;; *) urgency='normal' ;; esac

mkdir -p "$QUEUE_DIR" 2>/dev/null; [ -d "$QUEUE_DIR" ] || die "queue missing"
chmod 0777 "$QUEUE_DIR" 2>/dev/null; [ -w "$QUEUE_DIR" ] || die "queue not writable"

id=$(next_id) || die "lock unavailable"; [ -n "$id" ] || die "empty id"
tmp="$QUEUE_DIR/.in.$$"
{
	printf 'AN1\n'; printf 'U=%s\n' "$(b64 "$urgency")"; printf 'A=%s\n' "$(b64 "$app")"
	printf 'I=%s\n' "$(b64 "$icon")"; printf 'X=%s\n' "$expire"
	if [ -n "$hints" ]; then printf '%s\n' "$hints" | while IFS= read -r h; do [ -n "$h" ] && printf 'h=%s\n' "$h"; done; fi
	printf 'T=%s\n' "$(b64 "$title")"; printf 'B=\n'; printf '%s' "$body"
} >"$tmp" || die "write failed"
mv -f "$tmp" "$QUEUE_DIR/msg-$(printf '%012d' "$id").msg" || die "drop failed"
trim
[ "$print_id" = 1 ] && printf '%s\n' "$id"
exit 0
