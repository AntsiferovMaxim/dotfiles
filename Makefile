SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

SH_FILES  := $(shell find macos -name '*.sh') shared/git/hooks/dispatch
ZSH_FILES := $(wildcard shared/shell/*)

.PHONY: help check lint format bootstrap audit secrets

help: ## Show available targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | \
		awk -F ':.*## ' '{ printf "  %-10s %s\n", $$1, $$2 }'

check: lint secrets ## Run every check (used by CI)

lint: ## Lint and syntax-check scripts and configs
	shellcheck $(SH_FILES)
	shfmt -d $(SH_FILES)
	for f in $(ZSH_FILES); do zsh -n "$$f"; done
	git config --file shared/git/gitconfig --includes --list > /dev/null
	ssh -T -G -F shared/ssh/config example.com > /dev/null
	jq empty shared/vscodium/settings.json
	swiftc -typecheck macos/config/keyboardctl.swift
	@echo "lint: OK"

secrets: ## Scan the repository for committed secrets
	gitleaks dir --redact --no-banner .

format: ## Format shell scripts in place
	shfmt -w $(SH_FILES)

bootstrap: ## Run the macOS bootstrap (without macOS preferences)
	./macos/bootstrap.sh

audit: ## Run the security audit
	bash macos/security/audit.sh
