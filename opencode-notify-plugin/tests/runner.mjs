// Drives a plugin instance with a scenario JSON and a fake event stream.
// argv: runner.mjs <path-to-plugin.js> <scenario-json>
import { rm } from "node:fs/promises";

const args = process.argv.slice(2);
const notifyPath = args.find((a) => a.endsWith(".js") && !a.endsWith("runner.mjs"));
const scenario = JSON.parse(args.find((a) => a.trimStart().startsWith("{")));

for (const [k, v] of Object.entries(scenario.env ?? {})) process.env[k] = v;
await rm("/tmp/opencode-notify-dedup", { recursive: true, force: true });

const { default: plugin } = await import(notifyPath);

const events = scenario.events ?? [];
const ctx = {
  location: { directory: scenario.directory ?? "/tmp/proj" },
  options: scenario.options ?? {},
  session: {
    get: async ({ sessionID }) => (scenario.sessions ?? {})[sessionID] ?? null,
  },
  event: {
    subscribe: async function* () {
      for (const e of events) {
        yield e;
        await new Promise((r) => setTimeout(r, e._delay ?? 30));
      }
      await new Promise((r) => setTimeout(r, scenario.tailMs ?? 400));
    },
  },
};

await plugin.setup(ctx);
// The plugin iterates events in its own async loop; give it time to drain.
let wait = scenario.tailMs ?? 400;
for (const e of events) wait += (e._delay ?? 30) + 60;
if (scenario.extraWaitMs) wait += scenario.extraWaitMs;
await new Promise((r) => setTimeout(r, wait));
process.exit(0);
