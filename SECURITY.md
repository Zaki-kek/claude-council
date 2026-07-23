# Security Policy

claude-council is a set of Bash scripts that shell out to third-party AI
provider APIs and CLI agents. This document describes the threat model, the
secret-handling rules, and the static gate that every change must clear.

## Threat model

The council orchestrator passes user-supplied prompts to external providers and
parses their JSON responses. The main risks are:

- **Secret leakage** - API keys ending up in git, logs, or process listings.
- **Shell injection** - untrusted prompt text breaking out of a command.
- **Unsafe cleanup** - a `rm -rf` expanding to an unintended path.

## Secrets: environment only, never in git

API keys are read from environment variables (or a local `.env` that is loaded
into the environment). They are never committed. The repository `.gitignore`
blocks the real-world patterns that would otherwise capture them:

- `.env`, `.env.*` (with `!.env.example` kept as a template)
- `*.pem`, `*.key`, `.jwt_secret`
- `secrets/`, `*_secret*`, `*_token*`
- `credentials.json`

Copy `.env.example` to `.env` and fill in your keys locally. `.env` stays on
your machine - do not sync it anywhere.

### Gemini key travels in the URL

The Gemini provider authenticates with a query parameter
(`${ENDPOINT}?key=${API_KEY}` in `scripts/providers/gemini.sh`). This is an API
constraint, not a choice. Because of it, **never log the full request URL** for
the Gemini path - a captured URL would expose the key. Debug output must redact
or omit the query string.

## Prompts are data, not code

User prompts are handed to `jq` as arguments via `--arg` / `--argjson`, so a
prompt is always treated as a JSON string value and can never inject shell or
`jq` syntax. See the `jq --arg` / `jq -n --arg` call sites in
`scripts/query-council.sh` (for example the result-assembly and error-record
branches). New code that embeds prompt or response text into JSON must follow
the same pattern - no string concatenation into a `jq` program.

## shellcheck as a condition of merge

Every push runs `shellcheck` at `severity=warning` over all `scripts/**/*.sh`
plus the test helpers, pinned to shellcheck **v0.10.0**. The gate must report
**zero diagnostics** - it is a hard condition of merge, not advisory. Two real
defects were fixed under this gate and are guarded by tests:

- A cleanup `trap` that expanded `$TEMP_DIR` at install time instead of when the
  signal fired (SC2064).
- A teardown `rm -rf "$DIR"/*` hardened with `"${DIR:?}"` so an empty variable
  can never expand to `/*` (SC2115).

Every remaining `# shellcheck disable=` carries an inline justification.

Run the same gate locally with `make lint` (or `bash scripts/dev/lint.sh`).

## Reporting a vulnerability

Do not open a public issue for a security problem. Report it privately through
the repository's GitHub "Report a vulnerability" (Security Advisories) flow, or
by a private message to the maintainer (Zaki-kek). Please include reproduction
steps and the affected script path.
