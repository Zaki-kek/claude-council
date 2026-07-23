#!/usr/bin/env bash
# ABOUTME: Leveled logger for council scripts - writes strictly to stderr
# ABOUTME: log_debug/info/warn/error gated by COUNCIL_LOG_LEVEL (default info)

# No `set -euo` here: this file is sourced into scripts that manage their own
# strict-mode. Every function is unbound-safe and returns 0 so it never trips
# a caller running under `set -e`.

# Map a level name to its numeric threshold. Unknown/empty -> info (1).
_council_log_level_num() {
    case "${1:-}" in
        debug) printf '0' ;;
        info)  printf '1' ;;
        warn)  printf '2' ;;
        error) printf '3' ;;
        *)     printf '1' ;;
    esac
    return 0
}

# Core: print "[LEVEL] message" to stderr iff the message level clears the
# configured threshold. stdout is never touched - the run-council.sh pipe
# depends on query-council.sh keeping stdout clean.
_council_log() {
    local msg_level="$1"
    shift
    local threshold_name="${COUNCIL_LOG_LEVEL:-info}"
    local msg_num threshold_num
    msg_num="$(_council_log_level_num "$msg_level")"
    threshold_num="$(_council_log_level_num "$threshold_name")"
    if (( msg_num >= threshold_num )); then
        local upper
        upper="$(printf '%s' "$msg_level" | tr '[:lower:]' '[:upper:]')"
        printf '[%s] %s\n' "$upper" "$*" >&2
    fi
    return 0
}

log_debug() { _council_log debug "$@"; return 0; }
log_info()  { _council_log info "$@"; return 0; }
log_warn()  { _council_log warn "$@"; return 0; }
log_error() { _council_log error "$@"; return 0; }
