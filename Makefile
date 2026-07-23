# ABOUTME: Developer entry points - `make check` mirrors the CI gates 1:1
# ABOUTME: test = bats suite, lint = pinned shellcheck, check = both

SHELLCHECK_VERSION := 0.10.0
SHELLCHECK_URL := https://github.com/koalaman/shellcheck/releases/download/v0.10.0/shellcheck-v0.10.0.linux.x86_64.tar.xz

.PHONY: test lint check install-tools help

help:
	@echo "Targets:"
	@echo "  make test          - run the bats suite (same command as CI)"
	@echo "  make lint          - run shellcheck over scripts + test helpers"
	@echo "  make check         - test + lint (== the merge gate)"
	@echo "  make install-tools - install bats + pinned shellcheck v$(SHELLCHECK_VERSION)"

# Exactly the CI baseline command. The macOS-only it2_set_tab_color case is
# excluded by full name; everything else gates every run.
test:
	COUNCIL_NO_PANE=1 COUNCIL_AUTO_CLOSE=1 bats --tap \
		--negative-filter "it2_set_tab_color emits escape when in iTerm2" \
		tests/*.bats

# Local shellcheck gate - same script the CI job would run.
lint:
	bash scripts/dev/lint.sh

check: test lint

# Reproducible tool install matching the CI pins. shellcheck is fetched as a
# pinned static binary straight from koalaman (no apt, no unpinned action).
install-tools:
	@command -v bats >/dev/null 2>&1 || { \
		echo "Install bats-core 1.14+ - see https://github.com/bats-core/bats-core#installation"; \
		exit 1; \
	}
	@if ! command -v shellcheck >/dev/null 2>&1 || ! shellcheck --version | grep -qF $(SHELLCHECK_VERSION); then \
		echo "Fetching shellcheck v$(SHELLCHECK_VERSION)..."; \
		curl -fsSL "$(SHELLCHECK_URL)" -o /tmp/shellcheck.tar.xz; \
		tar -xJf /tmp/shellcheck.tar.xz -C /tmp; \
		echo "Copy /tmp/shellcheck-v$(SHELLCHECK_VERSION)/shellcheck into a PATH dir (e.g. sudo install ... /usr/local/bin)"; \
	fi
	@echo "Tools ready."
