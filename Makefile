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
# root certificate interception
define ROOT_CERT_CMD
command -v openssl >/dev/null 2>&1 || { printf '\e[31;1mopenssl not found, aborting.\e[0m\n' >&2; exit 1; }; \
openssl s_client -showcerts -connect google.com:443 </dev/null 2>/dev/null \
	| awk '/BEGIN CERTIFICATE/,/END CERTIFICATE/{ if(/BEGIN/){pem=""} pem=pem $$0 "\n" } END{printf "%s", pem}'
endef

define ENSURE_ROOT_CERT
set -e; \
ROOT_PEM=$$($(ROOT_CERT_CMD)); \
[ -n "$$ROOT_PEM" ] || { printf '\e[31;1mFailed to retrieve root certificate.\e[0m\n' >&2; exit 1; }; \
mkdir -p .assets/certs && printf '%s' "$$ROOT_PEM" >.assets/certs/ca-cert-root.crt
endef
CLEANUP_ROOT_CERT = rm -f .assets/certs/ca-cert-root.crt

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

.PHONY: test test-unit test-legacy test-nix
test: test-unit test-legacy test-nix ## Run all tests (unit + Docker smoke)

test-unit: ## Run bats unit tests (fast, no Docker)
	@printf "\n\033[95;1m== Running unit tests ==\033[0m\n\n"
	@bats tests/bats/
	@pwsh -c '$$cfg = New-PesterConfiguration; $$cfg.Run.Path = "tests/pester/"; $$cfg.Run.Exit = $$true; $$cfg.Output.Verbosity = "Detailed"; Invoke-Pester -Configuration $$cfg'

test-legacy: ## Run Docker smoke test for legacy path
	@printf "\n\033[95;1m== Testing legacy path (linux_setup.sh) ==\033[0m\n\n"
	@$(ENSURE_ROOT_CERT) && \
		docker build --no-cache \
			-f .assets/docker/Dockerfile.test-legacy \
			--output type=image,name=lss-test-legacy,unpack=false . \
		&& printf "\n\033[32;1m>> Legacy test PASSED\033[0m\n\n" \
		&& docker rmi lss-test-legacy >/dev/null 2>&1; \
		$(CLEANUP_ROOT_CERT)

test-nix: ## Run Docker smoke test for nix path
	@printf "\n\033[95;1m== Testing nix path (nix/setup.sh) ==\033[0m\n\n"
	@$(ENSURE_ROOT_CERT) && \
		docker build --no-cache \
			-f .assets/docker/Dockerfile.test-nix \
			--output type=image,name=lss-test-nix,unpack=false . \
		&& printf "\n\033[32;1m>> Nix test PASSED\033[0m\n\n" \
		&& docker rmi lss-test-nix >/dev/null 2>&1; \
		$(CLEANUP_ROOT_CERT)

.PHONY: mkdocs-serve
mkdocs-serve: ## Serve mkdocs documentation with live reload
	uv run --extra docs mkdocs serve --livereload

.PHONY: lint lint-diff lint-all
lint: ## Run pre-commit hooks for changed files
	@printf "🧭 Running pre-commit hooks for changed files...\n\n"
	git add --all && prek run
lint-diff: ## Run pre-commit hooks for files changed in this diff
	@printf "🧭 Running pre-commit hooks for files changed in this diff...\n\n"
	@if [ "$$(git branch --show-current)" = "main" ]; then \
		printf "⚠️  You are on the main branch. Skipping lint-diff.\n"; \
	else \
		git add --all && prek run --from-ref main --to-ref HEAD; \
	fi
lint-all: ## Run pre-commit hooks for all files
	@printf "🧭 Running pre-commit hooks for all files...\n\n"
	prek run --all-files
