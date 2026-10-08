# Notify Plugin

A notification plugin for OpenCode V2 using `notify-send`.

## Features

- Desktop notifications via `notify-send` (Linux/X11/Wayland)
- Notifications on: task completed (`session.execution.succeeded`), execution failed (`session.execution.failed`), permission request (`permission.asked`), question/form (`form.created`)
- Subagent events ignored to avoid duplicates
- Deduplication across plugin instances
- Throttling (1.5s) against notification spam

## Installation (OpenCode V2)

With a single command :

```bash
curl -fsSL https://github.com/saidani-proj/ai-box/releases/download/v1.0.0/opencode-notify-plugin-remote-install.sh | bash
```

This installs the plugin as `ai-box-notify` into `~/.config/opencode/plugins/ai-box-notify/`, and installs the uninstall program as `ai-box-opencode-notify-plugin-uninstall` into `~/.local/bin/` (adding it to your `PATH` in `~/.bashrc`/`~/.profile` if needed).

Restart OpenCode.

## Uninstallation

```bash
ai-box-opencode-notify-plugin-uninstall
```

This removes the plugin directory and the `ai-box-opencode-notify-plugin-uninstall` program itself.

## Original Author

Based on work by [alexcodeplace](https://github.com/alexcodeplace/opencode-timer-plugin).

