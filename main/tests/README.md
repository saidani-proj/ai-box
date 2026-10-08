# Tests — ai-box (`main`)

The test cases are described in [`CASES.yaml`](CASES.yaml) (tree of
`name` / `command` / `context` / `expect` / `children`).

## Running the tests

```sh
cd tests
python3 generate.py   # regenerates cases/*.sh from CASES.yaml
./run_all.sh
```

## Dependencies

- `bash`, `coreutils` (`timeout`, `mktemp`, `readlink`, `stat`)
- `python3` with the `yaml` module (PyYAML): `pip install pyyaml`
- **Docker is NOT required**: `docker` is simulated by `docker_mock.sh`
  (call log + container state), injected into `PATH` by `lib.sh`.
