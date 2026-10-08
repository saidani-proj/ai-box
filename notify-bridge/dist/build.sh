#!/usr/bin/env bash
# Build the notify-bridge distribution artifacts in this directory:
#   - notify-bridge-host-<version>.tar.gz      : host package
#                                                (install-host.sh, uninstall-host.sh, listener.sh)
#   - notify-bridge-container-<version>.tar.gz : container package
#                                                (install-container.sh, uninstall-container.sh, notify-send-shim.sh)
#
# Usage: ./build.sh
# The curl|bash bootstraps (notify-bridge-host-remote-install.sh, notify-bridge-container-remote-install.sh) and the download URLs live in dist/.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(dirname "$here")"

version="$(grep -oE "printf '[0-9.]+" "$root/src/listener.sh" | head -1 | grep -oE '[0-9.]+')"
[ -n "$version" ] || version="0.0.0"

host_archive="notify-bridge-host-${version}.tar.gz"
container_archive="notify-bridge-container-${version}.tar.gz"

tar -czf "$here/$host_archive" -C "$root/src" install-host.sh uninstall-host.sh listener.sh

echo "built $here/$host_archive"

tar -czf "$here/$container_archive" -C "$root/src" install-container.sh uninstall-container.sh notify-send-shim.sh

echo "built $here/$container_archive"
