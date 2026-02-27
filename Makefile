.PHONY: test test-id-generator test-file-ops test-json-utils test-verbose test-timing install-bats help

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

# Test targets
test: ## Run all tests
	@echo "$(BLUE)Running all tests...$(NC)"
	@bats tests/utils/

test-id-generator: ## Run ID generator tests only
	@echo "$(BLUE)Running ID generator tests...$(NC)"
	@bats tests/utils/test-id-generator.bats

test-file-ops: ## Run file operations tests only
	@echo "$(BLUE)Running file operations tests...$(NC)"
	@bats tests/utils/test-file-ops.bats

test-json-utils: ## Run JSON utils tests only
	@echo "$(BLUE)Running JSON utils tests...$(NC)"
	@bats tests/utils/test-json-utils.bats

test-verbose: ## Run all tests with verbose output
	@echo "$(BLUE)Running all tests (verbose)...$(NC)"
	@bats --tap tests/utils/

test-timing: ## Run all tests with timing information
	@echo "$(BLUE)Running all tests with timing...$(NC)"
	@bats --timing tests/utils/

# Installation targets
install-bats: ## Install bats-core (macOS with Homebrew)
	@echo "$(BLUE)Installing bats-core...$(NC)"
	@if command -v brew >/dev/null 2>&1; then \
		brew install bats-core; \
		echo "$(GREEN)✓ bats-core installed successfully$(NC)"; \
	else \
		echo "$(YELLOW)Homebrew not found. Please install bats manually.$(NC)"; \
		exit 1; \
	fi

install-jq: ## Install jq (macOS with Homebrew)
	@echo "$(BLUE)Installing jq...$(NC)"
	@if command -v brew >/dev/null 2>&1; then \
		brew install jq; \
		echo "$(GREEN)✓ jq installed successfully$(NC)"; \
	else \
		echo "$(YELLOW)Homebrew not found. Please install jq manually.$(NC)"; \
		exit 1; \
	fi

check-deps: ## Check if test dependencies are installed
	@echo "$(BLUE)Checking dependencies...$(NC)"
	@if command -v bats >/dev/null 2>&1; then \
		echo "$(GREEN)✓ bats is installed: $$(which bats)$(NC)"; \
		bats --version; \
	else \
		echo "$(YELLOW)✗ bats is not installed$(NC)"; \
		echo "  Run: make install-bats"; \
	fi
	@echo ""
	@if command -v jq >/dev/null 2>&1; then \
		echo "$(GREEN)✓ jq is installed: $$(which jq)$(NC)"; \
		jq --version; \
	else \
		echo "$(YELLOW)✗ jq is not installed$(NC)"; \
		echo "  Run: make install-jq"; \
	fi

# Documentation targets
test-summary: ## Display test summary
	@echo "$(BLUE)Test Suite Summary$(NC)"
	@echo ""
	@echo "Test Files:"
	@for file in tests/utils/*.bats; do \
		count=$$(grep -c '^@test' $$file); \
		echo "  - $$(basename $$file): $$count tests"; \
	done
	@echo ""
	@total=$$(grep -h '^@test' tests/utils/*.bats | wc -l); \
	echo "Total: $$total tests"

clean: ## Clean up temporary test files
	@echo "$(BLUE)Cleaning up temporary files...$(NC)"
	@find /tmp -name "tmp.*" -type d -mtime +1 -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

# Help target
help: ## Show this help message
	@echo "$(GREEN)Team Management System - Test Makefile$(NC)"
	@echo ""
	@echo "$(BLUE)Usage:$(NC)"
	@echo "  make [target]"
	@echo ""
	@echo "$(BLUE)Targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Examples:$(NC)"
	@echo "  make test              - Run all tests"
	@echo "  make test-id-generator - Run only ID generator tests"
	@echo "  make check-deps        - Check if dependencies are installed"
	@echo "  make test-summary      - Display test statistics"
