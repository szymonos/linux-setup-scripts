# Makefile for AI Search EEAT Project
# Provides convenient shortcuts for common development tasks

# Use bash for all commands to ensure consistent behavior across all invoking shells
SHELL := /bin/bash

# Default target
.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help message
	@printf 'Usage: make [target]\n\n'
	@printf "\033[1;97mAvailable targets:\033[0m\n"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[1;94m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: install
install: ## Install pre-commit hooks
	@printf "🔧 Installing pre-commit hooks...\n"
	prek install

.PHONY: update
update: ## Update prek and repositories versions
	@printf "\n✅ All dependencies upgraded\n\n"
	prek self update
	prek auto-update

.PHONY: lint lint-all lint-diff
lint: ## Run pre-commit hooks for changed files
	@printf "🧭 Running pre-commit hooks for changed files...\n\n"
	git add --all && prek run

lint-all: ## Run pre-commit hooks for all files
	@printf "🧭 Running pre-commit hooks for all files...\n\n"
	prek run --all-files

lint-diff: ## Run pre-commit hooks for files changed in this diff
	@printf "🧭 Running pre-commit hooks for files changed in this diff...\n\n"
	@[ "$$(git branch --show-current)" = "main" ] && printf "⚠️  You are on the main branch. Skipping lint-diff.\n" || prek run --from-ref main --to-ref HEAD
