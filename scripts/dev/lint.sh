#!/usr/bin/env bash
# ABOUTME: Local shellcheck gate - mirrors the CI 'shellcheck' job 1:1
# ABOUTME: Runs shellcheck (severity=warning) over every scripts/*.sh + tests/*.bash

# Not -e: shellcheck's own exit code is the signal we want to propagate.
set -uo pipefail

# Same pin as CI / Makefile / Dockerfile.
REQUIRED_VERSION="0.10.0"

if ! command -v shellcheck >/dev/null 2>&1; then
    echo "shellcheck not found - install v${REQUIRED_VERSION} (see CONTRIBUTING.md 'install-tools')." >&2
    exit 127
fi

INSTALLED_VERSION="$(shellcheck --version | awk '/^version:/ {print $2}')"
if [[ "$INSTALLED_VERSION" != "$REQUIRED_VERSION" ]]; then
    echo "warning: shellcheck ${INSTALLED_VERSION} found, CI pins ${REQUIRED_VERSION} - results may differ." >&2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT" || exit 1

# Collect targets via mapfile so lint.sh is itself shellcheck-clean; a bare
# $(find ...) here would trip SC2046 on this very file under -S warning.
mapfile -t TARGETS < <(find scripts -name '*.sh')

# SC1091: do not follow sourced files (paths resolved at runtime, not lint time).
shellcheck -S warning -e SC1091 "${TARGETS[@]}" tests/*.bash
exit $?
