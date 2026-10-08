#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: ai-box COMMAND [OPTIONS]"
    echo
    echo "Commands:"
    echo "  install   Create the ai-box"
    echo "  uninstall Remove the ai-box"
    echo "  up        Point workdir to \$PWD, start the box and exec into it"
    echo "  down      Stop the ai-box"
    echo "  exe       Execute a shell in the running box as current user"
    echo "  root      Execute a shell in the running box as root"
    echo
    echo "Options:"
    echo "  --id NAME        Use a named box: container ai-box-NAME, workdir ~/.ai-box/work-NAME (default: ai-box, ~/.ai-box/work)"
    echo "  --disable-net    Do not map host.docker.internal to the host (install only, default on)"
    echo "  --disable-notifs Do not mount ~/.ai-box/notifs at /notifs (install only, default on)"
    echo "  --               Everything after '--' is passed to 'docker create' (install only)"
    echo "  --version        Print the version number (1.0.0) and exit"
}

cmd="${1:-}"
shift || true

if [ "$cmd" = "--version" ]; then
    echo "ai-box 1.0.0"
    exit 0
fi

id=""
add_net=1
add_notifs=1
mount_opt=0
create_opts=()

while [ $# -gt 0 ]; do
    case "$1" in
        --id)
            [ $# -ge 2 ] || { echo "Error: --id needs a value" >&2; exit 1; }
            id="$2"; shift 2
            ;;
        --id=*)
            id="${1#*=}"; shift
            ;;
        --disable-net)
            add_net=0; mount_opt=1; shift
            ;;
        --disable-notifs)
            add_notifs=0; mount_opt=1; shift
            ;;
        --version)
            echo "ai-box 1.0.0"; exit 0
            ;;
        --)
            shift
            create_opts=("$@")
            break
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

name="ai-box"
[ -n "$id" ] && name="ai-box-$id"

workdir="$HOME/.ai-box/work"
[ -n "$id" ] && workdir="$HOME/.ai-box/work-$id"
workdir_rel="~${workdir#$HOME}"

if [ "$cmd" != "install" ] && [ "$mount_opt" -eq 1 ]; then
    echo "Error: --disable-net/--disable-notifs only apply to install" >&2
    exit 1
fi
if [ "$cmd" != "install" ] && [ ${#create_opts[@]} -gt 0 ]; then
    echo "Error: options after '--' only apply to install" >&2
    exit 1
fi

case "$cmd" in
    install)
        args=(create -it)
        [ "$add_net" -eq 1 ] && args+=(--add-host=host.docker.internal:host-gateway)
        [ "$add_notifs" -eq 1 ] && args+=(-v "$HOME/.ai-box/notifs:/notifs")
        args+=(-v "$workdir:/work")
        [ ${#create_opts[@]} -gt 0 ] && args+=("${create_opts[@]}")
        args+=(--name "$name" ubuntu:26.04)
        docker "${args[@]}" > /dev/null
        ;;
    uninstall)
        docker stop "$name" > /dev/null
        docker rm "$name" > /dev/null
        rm -f "$workdir"
        ;;
    up)
        case "$PWD" in
            "$workdir" | "$workdir/"*)
                echo "Error: \$PWD is inside $workdir_rel, which up would re-point to itself." >&2
                echo "Run up from a directory outside $workdir_rel." >&2
                exit 1
                ;;
        esac
        docker stop "$name" > /dev/null
        mkdir -p ~/.ai-box/notifs
        rm -f "$workdir"
        ln -s "$PWD" "$workdir"
        docker start "$name" > /dev/null
        docker exec -it -u "$(id -u):$(id -g)" -w /work "$name" bash
        ;;
    down)
        docker stop "$name" > /dev/null
        ;;
    exe)
        docker exec -it -u "$(id -u):$(id -g)" -w /work "$name" bash
        ;;
    root)
        docker exec -it "$name" bash
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        echo "Unknown command: $cmd" >&2
        usage
        exit 1
        ;;
esac
