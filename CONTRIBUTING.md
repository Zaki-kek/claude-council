# Contributing

Thanks for helping improve claude-council. This is a Bash/bats project - there
is no Python, no build step, and no package manager. Keep changes small and
gated.

## The gate: `make check` == CI

Before opening a pull request, run:

```bash
make check
```

`make check` runs exactly what CI runs:

- `make test` - the bats suite via
  `bats --tap --negative-filter "it2_set_tab_color emits escape when in iTerm2" tests/*.bats`
  (the excluded case is macOS-only and cannot pass on a Linux runner).
- `make lint` - `shellcheck` at `severity=warning` over every
  `scripts/**/*.sh` plus `tests/*.bash`, pinned to v0.10.0.

Both must be green. The shellcheck gate must report **zero diagnostics** - it is
a condition of merge.

## Toolchain and pins

- **bats-core 1.14+** - the test runner.
- **shellcheck v0.10.0** - pinned exactly; CI fetches the static binary straight
  from koalaman. Match it locally with `make install-tools`.
- **jq** - used for all JSON handling.

## Style

- **Executables vs sourced libs.** Top-level entry points
  (`scripts/query-council.sh`, `scripts/run-council.sh`, and the other directly
  invoked scripts) start with `set -euo pipefail`. Files under `scripts/lib/`
  that are `source`d into another script's context intentionally **do not** set
  strict mode - do not add it, it would change the caller's behavior.
- **Quote expansions.** Double-quote variable expansions; a `rm -rf` on a
  variable path must use `"${var:?}"` so it can never expand to `/*`.
- **Silence shellcheck only with a reason.** Every `# shellcheck disable=` line
  must carry an inline justification. Prefer fixing over disabling.
- **New behavior is covered by bats.** Add tests alongside the change; CI-safe
  tests avoid the network, real API keys, tmux, and macOS-only binaries.
- Use plain hyphens in prose, not long dashes.

## Logging

Diagnostics go to **stderr** via the leveled helpers in `scripts/lib/log.sh`
(`log_debug` / `log_info` / `log_warn` / `log_error`, threshold set by
`COUNCIL_LOG_LEVEL`, default `info`). stdout is a data channel - keep it clean
so the `run-council.sh` pipe is not corrupted. Prompt and response bodies are
logged only at `debug`.

## Known debt

- `scripts/query-council.sh` is ~610 lines, over the 400-line guideline. A
  structural split (argument parsing, provider dispatch, output assembly) is
  tracked as a separate task and intentionally out of scope for incremental
  changes - do not bundle a rewrite into an unrelated PR.
