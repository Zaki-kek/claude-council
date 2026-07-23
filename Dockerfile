# ABOUTME: Reproducible test/lint environment for claude-council (mock-only)
# ABOUTME: Runs the bats unit suite + pinned shellcheck; NO provider keys baked in

# Pinned base image so the environment never drifts.
FROM debian:bookworm-slim

# Pinned versions - shellcheck matches CI / Makefile / scripts/dev/lint.sh.
ARG SHELLCHECK_VERSION=v0.10.0
ARG BATS_VERSION=v1.14.0

# jq for JSON handling, git+bash+xz for tooling, curl to fetch pinned binaries.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash ca-certificates curl git jq xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Pinned shellcheck static binary straight from koalaman (no apt, no drift).
RUN curl -fsSL \
        "https://github.com/koalaman/shellcheck/releases/download/v0.10.0/shellcheck-v0.10.0.linux.x86_64.tar.xz" \
        -o /tmp/shellcheck.tar.xz \
    && tar -xJf /tmp/shellcheck.tar.xz -C /tmp \
    && install "/tmp/shellcheck-${SHELLCHECK_VERSION}/shellcheck" /usr/local/bin/shellcheck \
    && rm -rf /tmp/shellcheck.tar.xz "/tmp/shellcheck-${SHELLCHECK_VERSION}" \
    && shellcheck --version | grep -F 0.10.0

# Pinned bats-core.
RUN git clone --depth 1 --branch "${BATS_VERSION}" \
        https://github.com/bats-core/bats-core.git /opt/bats \
    && /opt/bats/install.sh /usr/local \
    && bats --version

WORKDIR /app
COPY . /app

# Never spawn the streaming tmux pane; belt-and-suspenders auto-close.
ENV COUNCIL_NO_PANE=1 \
    COUNCIL_AUTO_CLOSE=1

# Honest scope: this image runs the UNIT + MOCK gate (bats + shellcheck) only.
# Live provider integration needs real API keys and is deliberately NOT baked in.
# Default command mirrors the CI bats baseline (macOS-only case excluded by name).
CMD ["bash", "-lc", "bats --tap --negative-filter \"it2_set_tab_color emits escape when in iTerm2\" tests/*.bats"]
