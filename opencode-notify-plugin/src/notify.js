// V2 plugin contract: default-exports a definition with `id` and `setup` (or `effect`).
// `Plugin.define` from "@opencode/plugin" is a typing helper only, so it is intentionally
// not imported here: this file lives in the global config dir with no node_modules to
// resolve it from.
//
// Delivery goes through dev-notify-bridge, an HTTP bridge that runs on the host and
// relays notifications to the host desktop (node-notifier). The previous version
// shelled out to osascript/afplay/terminal-notifier, which only exist on macOS and
// cannot work from inside a container.
import { mkdir, open, readdir, stat, unlink } from "node:fs/promises"
import { exec } from "node:child_process"
import { promisify } from "node:util"

const execAsync = promisify(exec)


// Never let a slow or absent notification command stall session events.
const REQUEST_TIMEOUT_MS = 3000
const THROTTLE_MS = 1500
const UNREACHABLE_LOG_MS = 60_000

// Every open session loads its own instance of this plugin, and every instance
// subscribes to the same public event stream. So one completion event reaches N
// instances and would produce N desktop notifications. Instances therefore agree
// on a single notifier for each event with an atomic file claim keyed by the
// event id: the first instance to create `<eventID>.lock` pushes, the rest skip.
// Claims expire after CLAIM_TTL_MS so a crash or a slow fanout cannot block a
// re-delivery forever. Disable with DEV_NOTIFY_DEDUPE=0.
const DEDUP_DIR = "/tmp/opencode-notify-dedup"
const CLAIM_TTL_MS = 8000

const dedupeEnabled = () => (process.env.DEV_NOTIFY_DEDUPE ?? "1") !== "0"

// DEV_NOTIFY_DEBUG=1 logs every event type that reaches the plugin, so a new
// blocking state can be identified from the log instead of guessed at.
const debugEnabled = () => (process.env.DEV_NOTIFY_DEBUG ?? "0") !== "0"

// Bun.write(..., { append: true }) silently overwrites on Bun 1.4.x, which made this log
// keep only its last line and hid every failure. appendFile actually appends.
const appendLog = async (line) => {
  // Logging disabled
}

export default {
  id: "notify",

  async setup(ctx) {
    const directory = ctx.location.directory
    const options = ctx.options ?? {}
    let lastNotificationAt = 0
    let lastUnreachableLogAt = 0

    const nameFromDirectory = (dir) => {
      const parts = String(dir).split("/").filter(Boolean)
      return parts.length ? parts[parts.length - 1] : "OpenCode"
    }

    const projectName = () => nameFromDirectory(directory)

    // Every instance subscribes to the whole server stream, not just its own
    // location, so an event from another project can be won by the dedupe race in
    // any instance. Labelling it with this instance's directory then names the
    // wrong project. Events that carry `location` answer it directly; the
    // session.execution.* and permission.asked events do not, so their session is
    // resolved instead. Either way the label is right no matter who notifies.
    // A subagent runs as a child session, so the same lookup reports `child`.
    const describeEvent = async (event) => {
      const sessionID = event.data?.sessionID ?? event.data?.form?.sessionID
      let session
      if (sessionID) {
        try {
          session = await ctx.session.get({ sessionID })
        } catch (error) {
          await appendLog(`session lookup failed | ${sessionID} | ${error}`)
        }
      }
      const dir = event.location?.directory ?? session?.location?.directory
      return { project: dir ? nameFromDirectory(dir) : projectName(), child: Boolean(session?.parentID) }
    }

    // notify-send command (can be overridden via option or env var)
    const notifyCommand = () => String(options.notifyCommand ?? process.env.DEV_NOTIFY_COMMAND ?? "notify-send")

    // A stable identity shared by every instance that receives the same event.
    const eventKey = (event) => {
      if (event.id) return String(event.id).replace(/[^A-Za-z0-9._-]/g, "_")
      // Without an event id, fall back to the subject the event is about. Forms
      // carry their own identity, so one form can never collide with another.
      const data = event.data ?? {}
      const subject = data.form?.id ?? data.id ?? data.sessionID ?? ""
      return `${event.type}_${subject}_${data.durable?.seq ?? 0}`.replace(/[^A-Za-z0-9._-]/g, "_")
    }

    // The `question` tool (and anything else built on session forms) blocks the
    // session on `form.created` with no accompanying permission request, so this
    // is the only event that announces it. The interesting text lives in the
    // form fields: `title` is the short header, `description` the full question.
    const questionText = (form) => {
      const fields = Array.isArray(form?.fields) ? form.fields : []
      const text = fields
        .map((field) => [field?.title, field?.description].map((part) => String(part ?? "").trim()).filter(Boolean).join(" — "))
        .filter(Boolean)
        .join("\n")
      const fallback = String(form?.title ?? "").trim() || "OpenCode is waiting for your answer"
      const full = text || fallback
      return full.length > 300 ? `${full.slice(0, 299)}…` : full
    }

    // Atomically claim the right to notify for this event. True = this instance
    // won; false = another instance already took it (or owns a fresh claim).
    const claim = async (key) => {
      await mkdir(DEDUP_DIR, { recursive: true }).catch(() => {})
      const path = `${DEDUP_DIR}/${key}.lock`
      try {
        const handle = await open(path, "wx")
        await handle.writeFile(String(Date.now()))
        await handle.close()
        // Opportunistic cleanup of claims that outlived their TTL.
        await cleanupClaims()
        return true
      } catch (error) {
        if (error?.code !== "EEXIST") {
          // Fail open: never let lock trouble swallow a notification.
          await appendLog(`dedup: claim error | ${key} | ${error}`)
          return true
        }
        try {
          const claimStat = await stat(path)
          if (Date.now() - claimStat.mtimeMs > CLAIM_TTL_MS) {
            await unlink(path).catch(() => {})
            return claim(key)
          }
        } catch {}
        return false
      }
    }

    const cleanupClaims = async () => {
      try {
        const names = await readdir(DEDUP_DIR)
        const cutoff = Date.now() - CLAIM_TTL_MS * 10
        await Promise.all(
          names.map(async (name) => {
            if (!name.endsWith(".lock")) return
            const path = `${DEDUP_DIR}/${name}`
            try {
              const st = await stat(path)
              if (st.mtimeMs < cutoff) await unlink(path)
            } catch {}
          }),
        )
      } catch {}
    }

    const push = async ({ title, message, sound }) => {
      const now = Date.now()
      if (now - lastNotificationAt < THROTTLE_MS) {
        await appendLog(`throttled: ${title} | ${message}`)
        return
      }
      lastNotificationAt = now

      await appendLog(`notify: ${title} | ${message} | sound=${sound}`)

      try {
        const cmd = notifyCommand()
        // Escape quotes for shell safety
        const escapedTitle = String(title).replace(/"/g, '\\"')
        const escapedMessage = String(message).replace(/"/g, '\\"')
        const command = `${cmd} "${escapedTitle}" "${escapedMessage}"`
        await execAsync(command, { timeout: REQUEST_TIMEOUT_MS })
        lastUnreachableLogAt = 0
        await appendLog("notify-send: ok")
      } catch (error) {
        // notify-send may not be installed or fail. Log the first failure of a burst.
        if (now - lastUnreachableLogAt > UNREACHABLE_LOG_MS) {
          lastUnreachableLogAt = now
          await appendLog(`notify-send: failed | ${error}`)
        }
      }
    }

    // Plugin loaded

    const controller = new AbortController()

    void (async () => {
      for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
        try {
          if (debugEnabled()) {}

          // V2 server events. "session.idle" is a TUI-side event that is never
          // emitted on the server stream; completions surface as
          // session.execution.{succeeded,failed}. "form.created" is how the
          // question tool announces itself: the session blocks on the answer with
          // no permission request and no idle transition. Interrupts are
          // deliberately silent: a stop is usually the user's own action or a
          // deliberate change of direction, so it is not worth a notification.
          const notify =
            event.type === "session.execution.succeeded"
              ? { message: "Task complete", sound: true }
              : event.type === "session.execution.failed"
                ? { message: "Session error", sound: true }
                : event.type === "permission.asked"
                  ? { message: "OpenCode needs your approval", sound: true }
                  : event.type === "form.created"
                    ? { message: `Question: ${questionText(event.data?.form)}`, sound: true }
                    : null

          if (!notify) continue

          const { project, child } = await describeEvent(event)

          // A subagent is a child session with its own session.execution.* events,
          // so it reports "Task complete" once and the root session reports it
          // again: every subagent would add a desktop notification of its own.
          // Only the root outcome is worth a notification. A question or an
          // approval request from a subagent is left alone, because those block
          // the user whoever asks.
          if (child && event.type.startsWith("session.execution.")) {
            // Subagent outcome ignored
            continue
          }

          // All instances receive every event; only one of them may notify.
          const key = eventKey(event)
          if (dedupeEnabled() && !(await claim(key))) {
            await appendLog(`dedup: skipped ${key} (another instance notifies)`)
            continue
          }

          await push({ title: `OpenCode - ${project}`, message: notify.message, sound: notify.sound })
        } catch (error) {
          await appendLog(`handler: failed | ${event.type} | ${error}`)
        }
      }
    })()

    return () => {
      controller.abort()
    }
  },
}
