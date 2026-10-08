`ai-box` is a tool (a single Bash file, `ai-box.sh`) that creates and drives
a **box**: an Ubuntu 26.04 Docker container in which you can install, run and
test an AI agent — and any tool it needs — without touching your own system.

The box is **headless** and shares a working directory with the host: it
mounts `~/.ai-box/work` at `/work`, re-pointed to the directory you launch
it from, so files edited inside the box are edited on the host.

Sub-commands:

```
ai-box install     Create the box
ai-box up          Point workdir to $PWD, start the box and enter it
ai-box exe         Run a shell in the box (current user)
ai-box root        Run a shell in the box (administrator)
ai-box down        Stop the box
ai-box uninstall   Remove the box
```

Useful options: `--id NAME` for a named box, `--disable-net` /
`--disable-notifs` at install time, and anything after `--` is forwarded
to `docker create`.

For details: [`main/README.md`](main/README.md).

Install it with:

```bash
curl -fsSL https://github.com/saidani-proj/ai-box/releases/download/v1.0.0/ai-box-remote-install.sh | bash
```

Remove it with `ai-box-uninstall`. Inside the box, run `apt update` as root
before any `apt install`, and installing `sudo` first is recommended.

## notify-bridge (`notify-bridge/`)

Forwards desktop notifications raised inside the container to the host's
notification daemon, via a file queue on a shared volume: a shim replaces
`notify-send` in the container, and a listener on the host turns each queued
message into a real `notify-send` call.

How it works: inside the box, every `notify-send` call lands in the shared
queue volume; a small listener on the host (started automatically at login)
picks each message up within a second and shows it with the real desktop
`notify-send`. The queue is capped at 100 messages, so a dead listener
cannot fill the volume.

For details: [`notify-bridge/README.md`](notify-bridge/README.md).

Install it on the host with:

```bash
curl -fsSL https://github.com/saidani-proj/ai-box/releases/download/v1.0.0/notify-bridge-host-remote-install.sh | bash
```

And inside the container with:

```bash
curl -fsSL https://github.com/saidani-proj/ai-box/releases/download/v1.0.0/notify-bridge-container-remote-install.sh | bash
```

Each side is removed by its `ai-box-notify-bridge-uninstall` command.

## OpenCode notification plugin (`opencode-notify-plugin/`)

A plugin for OpenCode V2 that sends desktop notifications via `notify-send`
on key events (task completed, failure, permission requests, forms), with
deduplication and throttling.

It lives in `~/.config/opencode/plugins/ai-box-notify/` and only depends on
the plain `notify-send` command: inside the box that is the notify-bridge
shim, so the plugin works as-is against the bridge and could also fall back
to a real desktop bus if one existed. Behavior can be tuned with environment
variables (`DEV_NOTIFY_COMMAND`, `DEV_NOTIFY_DEDUPE`, `DEV_NOTIFY_DEBUG`).

For details: [`opencode-notify-plugin/README.md`](opencode-notify-plugin/README.md).

Install it with:

```bash
curl -fsSL https://github.com/saidani-proj/ai-box/releases/download/v1.0.0/opencode-notify-plugin-remote-install.sh | bash
```

Uninstall with `ai-box-opencode-notify-plugin-uninstall`.

## Assembly

In practice: ai-box mounts `~/.ai-box/notifs` at `/notifs`; inside, the
OpenCode plugin calls `notify-send`, which is the notify-bridge shim; the
message crosses the shared queue and shows up on the host desktop.

Typical setup:

```bash
# host: create and enter the box
ai-box install && ai-box up
# host: listener + autostart entry
curl -fsSL https://github.com/saidani-proj/ai-box/releases/download/v1.0.0/notify-bridge-host-remote-install.sh | bash
# inside the box: notify-send shim, then the OpenCode plugin
curl -fsSL https://github.com/saidani-proj/ai-box/releases/download/v1.0.0/notify-bridge-container-remote-install.sh | bash
curl -fsSL https://github.com/saidani-proj/ai-box/releases/download/v1.0.0/opencode-notify-plugin-remote-install.sh | bash
```
