#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="ai-box-notify"
PLUGIN_DIR="${HOME}/.config/opencode/plugins/${PLUGIN_NAME}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The plugin runs inside OpenCode: refuse to install when it is not present.
if ! command -v opencode > /dev/null 2>&1; then
  echo "Error: 'opencode' not found in PATH; install OpenCode before installing this plugin." >&2
  exit 1
fi

# If a version is already installed, uninstall it first.
if [ -d "${PLUGIN_DIR}" ]; then
  echo "Existing installation found, uninstalling first..."
  if [ -x "${SCRIPT_DIR}/uninstall.sh" ]; then
    bash "${SCRIPT_DIR}/uninstall.sh"
  else
    rm -rf "${PLUGIN_DIR}"
    echo "Removed ${PLUGIN_DIR}"
  fi
fi

mkdir -p "${PLUGIN_DIR}"
cp "${SCRIPT_DIR}/notify.js" "${PLUGIN_DIR}/index.js"

cat > "${PLUGIN_DIR}/package.json" << 'EOF'
{
  "name": "ai-box-notify",
  "version": "1.0.0",
  "type": "module",
  "main": "index.js"
}
EOF

cat > "${PLUGIN_DIR}/opencode.json" << 'EOF'
{
  "$schema": "https://opencode.ai/config.schema.json",
  "plugin": ["./index.js"]
}
EOF

# Install the uninstall program named ai-box-opencode-notify-plugin-uninstall on PATH.
BIN_DIR="${HOME}/.local/bin"
mkdir -p "${BIN_DIR}"
cp "${SCRIPT_DIR}/uninstall.sh" "${BIN_DIR}/ai-box-opencode-notify-plugin-uninstall"
chmod +x "${BIN_DIR}/ai-box-opencode-notify-plugin-uninstall"

# Make sure ${BIN_DIR} is on PATH, otherwise ai-box-opencode-notify-plugin-uninstall won't be found.
case ":${PATH}:" in
  *":${BIN_DIR}:"*) ;;
  *)
    ADDED=0
    ANY_RC=0
    for RC in "${HOME}/.bashrc" "${HOME}/.bash_profile" "${HOME}/.bash_login" "${HOME}/.profile" "${HOME}/.zshrc"; do
      if [ -f "${RC}" ]; then
        ANY_RC=1
        HAS=0
        grep -qF "${BIN_DIR}" "${RC}" 2>/dev/null && HAS=1
        if [ "${BIN_DIR}" = "${HOME}/.local/bin" ] && grep -qF '$HOME/.local/bin' "${RC}" 2>/dev/null; then
          HAS=1
        fi
        if [ "${HAS}" -eq 0 ]; then
          printf '\n# Added by ai-box-notify-plugin installer\nexport PATH="%s:$PATH"\n' "${BIN_DIR}" >> "${RC}"
          echo "Added ${BIN_DIR} to PATH in ${RC}"
          ADDED=1
        fi
      fi
    done
    case "${SHELL:-}" in
      */zsh)
        if [ ! -f "${HOME}/.zshrc" ]; then
          printf '# Added by ai-box-notify-plugin installer\nexport PATH="%s:$PATH"\n' "${BIN_DIR}" > "${HOME}/.zshrc"
          echo "Added ${BIN_DIR} to PATH in ${HOME}/.zshrc"
          ADDED=1
        fi
        ;;
    esac
    if [ "${ADDED}" -eq 0 ] && [ "${ANY_RC}" -eq 0 ]; then
      printf '# Added by ai-box-notify-plugin installer\nexport PATH="%s:$PATH"\n' "${BIN_DIR}" > "${HOME}/.bashrc"
      echo "Added ${BIN_DIR} to PATH in ${HOME}/.bashrc"
      ADDED=1
    fi
    if [ "${ADDED}" -eq 1 ]; then
      echo "NOTE: PATH was added to your shell rc files; exit the terminal and open a new one for it to take effect."
    fi
    ;;
esac

echo "Installed ${PLUGIN_NAME} to ${PLUGIN_DIR}"
echo "Uninstall program installed as ${BIN_DIR}/ai-box-opencode-notify-plugin-uninstall"
echo "Restart OpenCode to load the plugin."
