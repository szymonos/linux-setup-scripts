SHELL := /bin/bash

# Default target
.DEFAULT_GOAL := help

# MITM proxy support: use native TLS (OpenSSL) in prek to trust system CA certificates
export PREK_NATIVE_TLS := 1
# tell Node.js/npm to trust custom MITM proxy certificates (for prek-managed node hooks)
CA_CUSTOM := $(wildcard $(HOME)/.config/certs/ca-custom.crt)
ifdef CA_CUSTOM
export NODE_EXTRA_CA_CERTS := $(CA_CUSTOM)
endif

# Stage all changes, run prek, then restore previously staged file paths.
# Note: only path-level staging is preserved; partially-staged hunks become fully
# staged after the round-trip. Auto-fixes from hooks land in the working tree.
define PREK_RUN
sf=$$(mktemp); git diff --cached --name-only -z >$$sf; \
git add --all && prek run $(HOOK) $(1); rc=$$?; \
git reset -q HEAD; \
if [ -s $$sf ]; then xargs -0 git add -- <$$sf 2>/dev/null; fi; \
rm -f $$sf; exit $$rc
endef

.PHONY: help
help: ## Show this help message
	@printf 'Usage: make [target]\n\n'
	@printf "\033[1;97mAvailable targets:\033[0m"
	@awk 'BEGIN {FS = ":.*?## "} /^\.PHONY:/ {printf "\n"} /^[a-zA-Z_-]+:.*?## / {printf "  \033[1;94m%-16s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: install upgrade
install: ## Install pre-commit hooks
	@printf "🔧 Installing pre-commit hooks...\n"
	prek install --overwrite
upgrade: ## Upgrade prek and hooks versions
	@printf "\n✅ All dependencies upgraded\n\n"
	prek auto-update

.PHONY: hooks
hooks: ## List available pre-commit hook IDs
	@awk '/- id:/ {print "  " $$3}' .pre-commit-config.yaml | sort -u

.PHONY: hooks lint lint-diff lint-all
lint: ## Run pre-commit hooks for changed files (HOOK=id to run one hook)
	@printf "🧭 Running pre-commit hooks for changed files...\n\n"
	@$(call PREK_RUN)
lint-diff: ## Run pre-commit hooks for files changed in this diff (HOOK=id to run one hook)
	@printf "🧭 Running pre-commit hooks for files changed in this diff...\n\n"
	@if [ "$$(git branch --show-current)" = "main" ]; then \
		printf "⚠️  You are on the main branch. Skipping lint-diff.\n"; \
	else \
		$(call PREK_RUN,--from-ref main --to-ref HEAD); \
	fi
lint-all: ## Run pre-commit hooks for all files (HOOK=id to run one hook)
	@printf "🧭 Running pre-commit hooks for all files...\n\n"
	@$(call PREK_RUN,--all-files)

.PHONY: test test-unit test-bats test-pester
test: test-unit ## Run all unit tests
test-unit: test-bats test-pester ## Run bats and Pester unit tests
test-bats: ## Run bats unit tests
	@printf "\n\033[95;1m== bats ==\033[0m\n\n"
	@bats tests/bats/
test-pester: ## Run Pester unit tests
	@printf "\n\033[95;1m== Pester ==\033[0m\n\n"
	@pwsh -nop -c '$$cfg = New-PesterConfiguration; $$cfg.Run.Path = "tests/pester/"; $$cfg.Run.Exit = $$true; $$cfg.Output.Verbosity = "Detailed"; Invoke-Pester -Configuration $$cfg'
