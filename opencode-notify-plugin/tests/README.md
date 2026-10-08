# Tests — opencode-notify-plugin

The test cases are described in [`CASES.yaml`](CASES.yaml) (tree of
`name` / `command` / `context` / `expect` / `children`).

## Running the tests

```sh
cd tests
python3 generate.py   # regenerates cases/*.sh from CASES.yaml
./run_all.sh
```

## Dependencies

- `bash`, `coreutils` (`timeout`, `mktemp`, `wc`)
- `python3` with the `yaml` module (PyYAML): `pip install pyyaml`
- `bun` binary in `PATH` (or `~/.bun/bin/bun`) — `notify.js` and
  `runner.mjs` run on the standalone Bun runtime (no `node_modules` needed);
  `opencode` itself is **not** required
- **`notify-send` and Node.js are NOT required**: `notify-send` is
  simulated by a mock injected into `PATH`
