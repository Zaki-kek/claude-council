#!/usr/bin/env bats
# ABOUTME: Regression tests for the query-council TEMP_DIR cleanup trap (S2 SC2064)
# ABOUTME: A bounded fake-key run must reach the trap and leave zero temp dirs

load test_helper

QUERY="${SCRIPTS_DIR}/query-council.sh"

setup() {
    # Isolated TMPDIR so we can count exactly what query-council leaves behind.
    ISO_TMP="$(mktemp -d)"
}

teardown() {
    [[ -n "${ISO_TMP:-}" && -d "$ISO_TMP" ]] && rm -rf "$ISO_TMP"
}

@test "trap-cleanup: bounded fake-key run leaves no temp dirs behind" {
    # fakekey is NOT a real secret - it only flips gemini 'available' so the
    # mktemp+trap path executes. MAX_RETRIES=0 + TIMEOUT=5 keep the curl bounded
    # so the run finishes fast even on a networked CI host.
    run env -u OPENAI_API_KEY -u GROK_API_KEY -u XAI_API_KEY -u PERPLEXITY_API_KEY \
        GEMINI_API_KEY=fakekey \
        COUNCIL_NO_PANE=1 COUNCIL_AUTO_CLOSE=1 \
        COUNCIL_MAX_RETRIES=0 COUNCIL_TIMEOUT=5 \
        TMPDIR="$ISO_TMP" \
        bash "$QUERY" ping
    # query-council exits 0 even when the provider call fails (it records the
    # error into the results JSON), so we assert on cleanup, not exit code.
    local leftover
    leftover="$(find "$ISO_TMP" -maxdepth 1 -mindepth 1 -type d | wc -l)"
    [ "$leftover" -eq 0 ]
}

@test "trap-cleanup: cleanup trap is single-quoted (deferred expansion)" {
    # Safety net independent of runtime - guards the S2 SC2064 fix from regressing.
    run grep -F "trap 'rm -rf" "$QUERY"
    [ "$status" -eq 0 ]
    [[ "$output" == *'"$TEMP_DIR"'* ]]
}

@test "trap-cleanup: repeated rm on empty dir is idempotent" {
    local d
    d="$(mktemp -d)"
    rm -rf "${d:?}"/*
    rm -rf "${d:?}"/*
    [ -d "$d" ]
    rmdir "$d"
}
