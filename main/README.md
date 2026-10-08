# ai-box (main)

`ai-box` is a single Bash command that creates and drives a **box**: a
Ubuntu 26.04 Docker container in which you can install, run and put
to test an **ai agent** — and any tool it needs — without touching your own
system. The box mounts the directory you are working in, so files are shared
with the host.

Install it with a single command:

```bash
curl -fsSL https://github.com/saidani-proj/ai-box/releases/download/v1.0.0/ai-box-remote-install.sh | bash
```

Remove the installed
commands with `ai-box-uninstall`. If the installer finds an existing installation, it first uninstalls it keeping the data
(`--keep-data`). The uninstaller
also offers to delete ai-box data (containers `ai-box*` and `~/.ai-box`)
after a confirmation prompt; pass `--keep-data` to keep it without
being asked.

## Commands

```
ai-box install     Create the box
ai-box uninstall   Remove the box
ai-box up          Point workdir to $PWD, start the box and enter it
ai-box down        Stop the box
ai-box exe         Run a shell in the box (current user)
ai-box root        Run a shell in the box (administrator)
ai-box help        Show help
```

## Options

- `--id NAME` uses a named box (`ai-box-NAME` container) instead of the
  default `ai-box` one, and mounts `~/.ai-box/work-NAME` instead of
  `~/.ai-box/work`. Accepted by all commands.
- `--disable-net` (install only, net on by default) skips mapping
  `host.docker.internal` to the host.
- `--disable-notifs` (install only, notifs on by default) skips mounting
  `~/.ai-box/notifs` at `/notifs`.
- `--` (install only): everything after `--` is passed verbatim to
  `docker create` (e.g. `ai-box install -- --cpus 2 -e FOO=bar`).

`--disable-net`/`--disable-notifs`/`--` are rejected on every command other
than `install`.

`--version` prints the version number (1.0.0) and exits.

## How it works

- `install` runs `docker create -it` on `ubuntu:26.04`, named `ai-box`
  (or `ai-box-NAME` with `--id`), always mounting the box workdir at `/work`
  (`~/.ai-box/work`, or `~/.ai-box/work-NAME` with `--id`), plus
  `--add-host=host.docker.internal:host-gateway` (unless `--disable-net`)
  and `-v ~/.ai-box/notifs:/notifs` (unless `--disable-notifs`). Extra
  options after `--` are forwarded to `docker create`.
- `up` stops the box, re-points the box workdir symlink to `$PWD`, starts
  the box
  and opens a shell as your user (same uid/gid as on the host) with `/work`
  as working directory.
- `exe` opens that same user shell without touching the workdir symlink.
- `root` opens a shell as administrator.
- `down` stops the box.
- `uninstall` stops the container, removes it and deletes only the work
  symlink (`~/.ai-box/work`, or `~/.ai-box/work-NAME` with `--id`).
  `~/.ai-box` itself is kept.
- The box is **headless**: no display server, terminal only. The working
  directory follows the directory you run `up` from because it is a symbolic
  link, so `ai agent` installed inside the box edits host files directly.

## Inside the box

- Before any `apt install`, run `apt update` as root:
  `ai-box root` then `apt update`.
- It is advised to install `sudo` (`apt install sudo`).