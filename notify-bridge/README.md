# notify-bridge

Forward desktop notifications raised **inside a container** to the
notification daemon of the **host** desktop.

Applications running in a container usually call `notify-send` or talk to
D-Bus directly. Neither works: the container has no session bus and no
notification daemon. `notify-bridge` replaces that path with a plain file
queue on a bind-mounted volume, and a small listener on the host that turns
each queued message into a real `notify-send` call.

No root, no system service, no D-Bus manipulation, nothing outside `$HOME`
on the host.

## How it works

```
container                                  host
---------                                  -----
notify-send "title" "body"
   |
   +-- writes out/msg-000000000042.msg ---> ai-box-notify-bridge-listener
       (staged as .in.<pid>, then renamed)     |
       header lines base64 encoded            +-- notify-send "title" "body"
       body stored raw                        +-- deletes the file
```

1. The container shim takes a monotonically increasing id from a counter on
   the shared volume, writes the message to `out/.in.<pid>`, then renames it
   to `out/msg-<id>.msg`. Because the rename is atomic, the listener never
   reads a half-written message.
2. The host listener polls the queue once per second. For each message it
   rebuilds the `notify-send` command line (`-a`, `-i`, `-u`, `-t`, `--hint`, `-p` output discarded)
   and calls `notify-send`, then deletes the file.
3. The queue is capped at 100 messages (`AI_BOX_NOTIF_MAX`). On overflow the
   oldest messages are dropped, so a host with a dead listener cannot fill
   the volume and the most recent notifications survive.

The queue directory is `$AI_BOX_NOTIF_DIR/out`, that is
`~/.ai-box/notifs/out` on the host and `/notifs/out` in the container. **The
mount point may differ, the shared directory must not.**

### Message format

`AN1` header, one `KEY=value` line per field, values base64 encoded, then
`B=` followed by the raw body (so newlines need no escaping):

```
AN1
U=<b64 urgency>
A=<b64 app name>
I=<b64 icon>
X=<expire ms>
h=<b64 hint>            (repeated)
T=<b64 summary>
B=
<body>
```

A file without the `AN1` line or without `B=` is debris (truncated write,
stray file) and is dropped. Aborted writes left as `.in.<pid>` are
removed after `AI_BOX_NOTIF_STALE` seconds (60 by default).

## Requirements

- **Host**: `notify-send` (`sudo apt install libnotify-bin`), `base64`, `flock` (util-linux), POSIX `sh`,
  coreutils (`date`, `stat`, `wc`, `chmod`, `mkdir`, `install`, `cat`, `rm`).
  A running desktop notification daemon.
- **Container**: POSIX `sh` and coreutils (`base64`, `tr`, `flock`, `chmod`,
  `mkdir`, `install`, `mv`, `rm`, `cat`) plus `grep` and `id` for the install
  script only. No D-Bus, no root, no
  network.

## Install

With a single command (recommended):

```sh
curl -fsSL https://github.com/saidani-proj/ai-box/releases/download/v1.0.0/notify-bridge-host-remote-install.sh | bash
```

The release ships two packages built by `dist/build.sh`:
`notify-bridge-host-<version>.tar.gz` and
`notify-bridge-container-<version>.tar.gz` 
Distro bootstraps: `dist/notify-bridge-host-remote-install.sh` (host) and
`dist/notify-bridge-container-remote-install.sh` (container).

### 1. On the host

```sh
curl -fsSL https://github.com/saidani-proj/ai-box/releases/download/v1.0.0/notify-bridge-host-remote-install.sh | bash
```

Installs `~/.local/bin/ai-box-notify-bridge-listener`,
`~/.local/bin/ai-box-notify-bridge-uninstall` and
`~/.config/autostart/ai-box-notify-bridge-listener.desktop`, and creates
`~/.ai-box/notifs/out`.

### 2. Mount the queue in the container

A mount must be made between the two queue directories (no specific command is
required — `~/.ai-box/notifs` on the host and `/notifs` in the container).

The queue is `chmod 0777`, so a different uid on either side still works. If
the container runs as a different user, keep the uids aligned to make the
diagnostics easier.

### 3. In the container

```sh
curl -fsSL https://github.com/saidani-proj/ai-box/releases/download/v1.0.0/notify-bridge-container-remote-install.sh | bash
```

It installs the shim as `~/.local/bin/notify-send`, the uninstaller as
`~/.local/bin/ai-box-notify-bridge-uninstall`, and checks that the volume
is present and writable. Make sure `~/.local/bin` is in `PATH` (interactive
shells usually get that from `.bashrc`; in a non-interactive shell prepend it
explicitly).

### 4. Log out and back in

The XDG autostart entry is only read at session login. Starting the listener
by hand works too:

```sh
~/.local/bin/ai-box-notify-bridge-listener &
```

The listener also accepts `--once` (drain the queue once and exit) and
`--interval SECONDS` (polling period, default 1).

## Verify

From the container:

```sh
notify-send "notify-bridge" "hello from the container"
```

The popup must appear on the host desktop within a second or so. Useful
variants: `notify-send -u critical -t 0 "title" "body"` (never expires),
`notify-send -p ...` (prints the local id).

## Configuration

| Variable | Default | Used by | Meaning |
| --- | --- | --- | --- |
| `AI_BOX_NOTIF_DIR` | `~/.ai-box/notifs` (host), `/notifs` (container) | both | Shared queue directory |
| `AI_BOX_NOTIF_BIN` | `~/.local/bin` | both install scripts | Where files are installed |
| `AI_BOX_NOTIF_SEND` | `notify-send` (from `PATH`) | listener | `notify-send` to call |
| `AI_BOX_NOTIF_MAX` | `100` (`0` = unlimited) | shim | Queue ceiling |
| `AI_BOX_NOTIF_STALE` | `60` | listener | Age before a `.in.*` is reaped |
| `AI_BOX_NOTIF_VERBOSE` | `0` | shim | `1` prints queue overflow warnings |

The listener calls `notify-send` by name, so `PATH` decides which binary is
used. On the host that must be the real one (`/usr/bin/notify-send`), never
the shim: the listener probes `--version` at startup and refuses to start if
it finds itself. Use `AI_BOX_NOTIF_SEND` to point at a specific path.

## Limitations

- `--replace-id` is accepted and ignored: the bridge keeps no daemon state,
  so every notification is new. The id printed by `--print-id` is local to
  the queue and cannot be used with `-r`.
- Restarting the listener **empties** the queue. It is a reset, not a drain.
- Only one listener per queue: the second one exits immediately (lock file).
- The host listener polls once per second; bursts are sent one by one.
- Anything the application does over D-Bus besides notifications (progress
  bars, actions, image attachments) is out of scope.

## Uninstall

Run the installed `ai-box-notify-bridge-uninstall` on each side. It removes the
components and itself:

Host:

```sh
rm -f ~/.local/bin/ai-box-notify-bridge-listener
rm -f ~/.local/bin/ai-box-notify-bridge-uninstall
rm -f ~/.config/autostart/ai-box-notify-bridge-listener.desktop
rm -rf ~/.ai-box/notifs
```

Container: remove `~/.local/bin/notify-send` and `~/.local/bin/ai-box-notify-bridge-uninstall`, and drop the mount. Removing the shim is what restores the original
`notify-send`: with the shim still installed, dropping the mount only makes
every call fail (`queue missing`) or, as root, silently writes to a
container-local `/notifs`. The `PATH` line the installer added to your
shell rc files is left in place (harmless).