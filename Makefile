SHELL := /bin/bash

# Default target
.DEFAULT_GOAL := help

# -- Root certificate interception for MITM proxy ---------------------------
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
	prek self update
	prek auto-update

.PHONY: test test-legacy test-brew
test: test-legacy test-brew ## Run Docker smoke tests for both setup paths

test-legacy: ## Run Docker smoke test for legacy path
	@printf "\n\033[95;1m== Testing legacy path (linux_setup.sh) ==\033[0m\n\n"
	@$(ENSURE_ROOT_CERT) && \
		docker build --no-cache \
			-f .assets/docker/Dockerfile.test-legacy \
			-t lss-test-legacy . \
		&& printf "\n\033[32;1m>> Legacy test PASSED\033[0m\n\n" \
		&& docker rmi lss-test-legacy >/dev/null 2>&1; \
		$(CLEANUP_ROOT_CERT)

test-brew: ## Run Docker smoke test for brew path
	@printf "\n\033[95;1m== Testing brew path (brew/setup.sh) ==\033[0m\n\n"
	@$(ENSURE_ROOT_CERT) && \
		docker build --no-cache \
			-f .assets/docker/Dockerfile.test-brew \
			-t lss-test-brew . \
		&& printf "\n\033[32;1m>> Brew test PASSED\033[0m\n\n" \
		&& docker rmi lss-test-brew >/dev/null 2>&1; \
		$(CLEANUP_ROOT_CERT)

.PHONY: lint lint-diff lint-all
lint: ## Run pre-commit hooks for changed files
	@printf "🧭 Running pre-commit hooks for changed files...\n\n"
	git add --all && prek run
lint-diff: ## Run pre-commit hooks for files changed in this diff
	@printf "🧭 Running pre-commit hooks for files changed in this diff...\n\n"
	@[ "$$(git branch --show-current)" = "main" ] && printf "⚠️  You are on the main branch. Skipping lint-diff.\n" || prek run --from-ref main --to-ref HEAD
lint-all: ## Run pre-commit hooks for all files
	@printf "🧭 Running pre-commit hooks for all files...\n\n"
	prek run --all-files
