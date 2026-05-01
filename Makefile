SHELL := /bin/bash

# Default target
.DEFAULT_GOAL := help

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

.PHONY: test test-unit test-bats test-pester
test: test-unit ## Run all unit tests
test-unit: test-bats test-pester ## Run bats and Pester unit tests
test-bats: ## Run bats unit tests
	@printf "\n\033[95;1m== bats ==\033[0m\n\n"
	@bats tests/bats/
test-pester: ## Run Pester unit tests
	@printf "\n\033[95;1m== Pester ==\033[0m\n\n"
	@pwsh -nop -c '$$cfg = New-PesterConfiguration; $$cfg.Run.Path = "tests/pester/"; $$cfg.Run.Exit = $$true; $$cfg.Output.Verbosity = "Detailed"; Invoke-Pester -Configuration $$cfg'
