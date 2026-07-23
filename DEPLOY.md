# Deployment

claude-council ships as a Claude Code plugin - a directory of scripts, commands,
agents, and skills. There is no server to run and no build artifact to publish.

## Install as a plugin directory

Point Claude Code at this repository as a plugin (see `README.md` for the
marketplace / clone instructions). The council is driven through the plugin's
commands, which call `scripts/run-council.sh`.

## Provider requirements

The council queries whichever providers are configured at runtime:

- **API providers** - Gemini, OpenAI, Grok/xAI, Perplexity - each gated on its
  own key (`GEMINI_API_KEY`, `OPENAI_API_KEY`, `XAI_API_KEY` / `GROK_API_KEY`,
  `PERPLEXITY_API_KEY`).
- **CLI providers** - `codex`, `gemini` - gated on the binary being on `PATH`.

Copy `.env.example` to `.env` and fill in the keys you have. With no key and no
CLI agent available, `query-council.sh` exits non-zero with an empty stdout and
a "No providers configured" message on stderr - this is the documented contract
and is exercised by the CI mock-smoke job.

## What CI and Docker actually verify (honest scope)

The CI pipeline and the `Dockerfile` run **unit and mock checks only**:

- the bats suite (no network, no real keys, no tmux, no macOS-only binaries);
- the pinned shellcheck gate;
- a mock-smoke run that asserts the no-providers contract **without any real
  keys**.

Live integration against the real providers requires **real API keys** and is
**not** part of the gate - it is not baked into the image and cannot be, since
keys never live in git. Treat the containerized/CI run as a correctness and
lint harness, not as proof that a given provider responds.

## Logs and the stdout contract

`run-council.sh` runs `query-council.sh "$@" 2>/dev/null | format-output.sh`,
so it **discards stderr**. That means the leveled logger output
(`COUNCIL_LOG_LEVEL`, default `info`) is visible when you invoke
`query-council.sh` directly, but not when you go through the `run-council.sh`
wrapper. To see logs during troubleshooting, run `query-council.sh` yourself and
set `COUNCIL_LOG_LEVEL=debug`.

## Reproducible test/lint environment

Build the pinned container to reproduce the gate anywhere:

```bash
docker build -t claude-council-ci .
docker run --rm claude-council-ci   # runs the bats suite by default
```

The image installs `jq`, bats, and the pinned shellcheck v0.10.0, and defaults
its command to the same bats baseline used in CI.
