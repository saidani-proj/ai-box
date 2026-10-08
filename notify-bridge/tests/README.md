# Tests — notify-bridge (`notify-bridge`)

The test cases are described in [`CASES.yaml`](CASES.yaml) (tree of
`name` / `command` / `context` / `expect` / `children`).

## Running the tests

```sh
cd tests
python3 generate.py   # regenerates cases/*.sh from CASES.yaml
./run_all.sh
```

## Dependencies

- `bash` / `sh`, `coreutils` (`timeout`, `mktemp`, `stat`, `touch`, `date`)
- `python3` with the `yaml` module (PyYAML): `pip install pyyaml`
- `base64`, `grep`, `flock`, `sed`
- **No desktop notification daemon is required**: `notify-send` is
  simulated by a mock created in `lib.sh` (calls logged to `$NS_LOG`,
  canned `--version` response). No real volume, container, or D-Bus needed.
