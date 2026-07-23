#!/usr/bin/env bats
# ABOUTME: Tests for scripts/lib/log.sh
# ABOUTME: Validates level filtering, stderr-only output, and crash-safety

load test_helper

LOG="${LIB_DIR}/log.sh"

setup() {
    # Per-test scratch dir bats creates and cleans up - keeps redirect targets
    # out of the repo working tree no matter where bats is invoked from.
    D="${BATS_TEST_TMPDIR}"
}

@test "log: warn level suppresses info but passes warn and error" {
    source "$LOG"
    COUNCIL_LOG_LEVEL=warn log_info "hidden" 2>"$D/info_err"
    COUNCIL_LOG_LEVEL=warn log_warn "shown-warn" 2>"$D/warn_err"
    COUNCIL_LOG_LEVEL=warn log_error "shown-error" 2>"$D/err_err"
    [ ! -s "$D/info_err" ]
    [ -s "$D/warn_err" ]
    [ -s "$D/err_err" ]
    grep -Fq "[WARN] shown-warn" "$D/warn_err"
    grep -Fq "[ERROR] shown-error" "$D/err_err"
}

@test "log: debug level passes every level" {
    source "$LOG"
    COUNCIL_LOG_LEVEL=debug log_debug "d" 2>"$D/d_err"
    COUNCIL_LOG_LEVEL=debug log_info "i" 2>"$D/i_err"
    COUNCIL_LOG_LEVEL=debug log_warn "w" 2>"$D/w_err"
    COUNCIL_LOG_LEVEL=debug log_error "e" 2>"$D/e_err"
    [ -s "$D/d_err" ]
    [ -s "$D/i_err" ]
    [ -s "$D/w_err" ]
    [ -s "$D/e_err" ]
}

@test "log: error level passes only error" {
    source "$LOG"
    COUNCIL_LOG_LEVEL=error log_debug "d" 2>"$D/d_err"
    COUNCIL_LOG_LEVEL=error log_info "i" 2>"$D/i_err"
    COUNCIL_LOG_LEVEL=error log_warn "w" 2>"$D/w_err"
    COUNCIL_LOG_LEVEL=error log_error "e" 2>"$D/e_err"
    [ ! -s "$D/d_err" ]
    [ ! -s "$D/i_err" ]
    [ ! -s "$D/w_err" ]
    [ -s "$D/e_err" ]
}

@test "log: writes to stderr and never to stdout" {
    source "$LOG"
    # Capture stdout separately; it must stay empty so the run-council pipe holds.
    COUNCIL_LOG_LEVEL=debug log_info "on-stderr" >"$D/stdout_cap" 2>"$D/stderr_cap"
    [ ! -s "$D/stdout_cap" ]
    [ -s "$D/stderr_cap" ]
    grep -Fq "[INFO] on-stderr" "$D/stderr_cap"
}

@test "log: unknown level is treated as info and does not crash" {
    source "$LOG"
    run env COUNCIL_LOG_LEVEL=bogus bash -c "source '$LOG'; log_info 'x'"
    [ "$status" -eq 0 ]
    # bogus -> info threshold, so an info message still surfaces on stderr.
    COUNCIL_LOG_LEVEL=bogus log_info "surfaced" 2>"$D/bogus_err"
    [ -s "$D/bogus_err" ]
}

@test "log: safe under set -u with unset COUNCIL_LOG_LEVEL" {
    run bash -c "set -u; unset COUNCIL_LOG_LEVEL; source '$LOG'; log_warn 'safe'"
    [ "$status" -eq 0 ]
    [[ "$output" == *"[WARN] safe"* ]]
}
