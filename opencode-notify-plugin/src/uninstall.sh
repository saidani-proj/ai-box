#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="ai-box-notify"
PLUGIN_DIR="${HOME}/.config/opencode/plugins/${PLUGIN_NAME}"

if [ -d "${PLUGIN_DIR}" ]; then
  rm -rf "${PLUGIN_DIR}"
  echo "Removed ${PLUGIN_DIR}"
else
  echo "${PLUGIN_NAME} is not installed (no ${PLUGIN_DIR})"
fi

# Remove the installed uninstall program too.
BIN_PATH="${HOME}/.local/bin/ai-box-opencode-notify-plugin-uninstall"
if [ -f "${BIN_PATH}" ]; then
  rm -f "${BIN_PATH}"
  echo "Removed ${BIN_PATH}"
fi
