# Makefile for terraform-aws-backup testing

.PHONY: help test test-unit test-integration test-resource-creation validate format lint security clean

# Variables
TERRAFORM_VERSION ?= 1.6.6
GO_VERSION ?= 1.21

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@egrep '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

install-deps: ## Install dependencies for testing
	@echo "Installing Go dependencies..."
	@if [ -f go.mod ]; then go mod download; fi
	@echo "Installing Python dependencies..."
	@pip install checkov

validate: ## Validate Terraform configuration
	@echo "Validating Terraform configuration..."
	@terraform init -upgrade
	@terraform validate
	@terraform fmt -check -recursive

format: ## Format Terraform files
	@echo "Formatting Terraform files..."
	@terraform fmt -recursive

lint: ## Run TFLint
	@echo "Running TFLint..."
	@tflint --init
	@tflint

security: ## Run security scanning with Checkov
	@echo "Running security scan with Checkov..."
	@checkov -d . \
		--framework terraform \
		--output cli \
		--skip-check CKV_AWS_1 \
		--quiet

validate-examples: ## Validate all examples
	@echo "Validating examples..."
	@for example in examples/*/; do \
		if [ -d "$$example" ]; then \
			echo "Validating $$example"; \
			cd "$$example" && \
			terraform init -upgrade && \
			terraform validate && \
			terraform fmt -check; \
			cd - > /dev/null; \
		fi; \
	done

test-unit: ## Run unit tests (validation only)
	@echo "Running unit tests..."
	@if [ -d test ]; then \
		cd test && go test -v -short ./...; \
	else \
		echo "No test directory found"; \
	fi

test-integration: ## Run integration tests (requires AWS credentials)
	@echo "Running integration tests..."
	@if [ -d test ]; then \
		cd test && go test -v -timeout 30m -run "^Test.*(?<!ResourceCreation)$$" ./...; \
	else \
		echo "No test directory found"; \
	fi

test-resource-creation: ## Run resource creation integration tests (requires AWS credentials)
	@echo "Running resource creation integration tests..."
	@echo "WARNING: This will create and destroy real AWS resources and may incur costs!"
	@if [ -d test ]; then \
		cd test && go test -v -timeout 60m -run TestResourceCreation ./...; \
	else \
		echo "No test directory found"; \
	fi

test: validate lint security validate-examples test-unit ## Run all tests except integration tests

test-all: test test-integration ## Run all tests including integration tests (but not resource creation)

test-full: test test-integration test-resource-creation ## Run all tests including resource creation tests

clean: ## Clean up test artifacts
	@echo "Cleaning up..."
	@rm -rf .terraform
	@rm -rf .terraform.lock.hcl
	@rm -rf versions_test.tf
	@find examples -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@find examples -name ".terraform.lock.hcl" -type f -delete 2>/dev/null || true

pre-commit: ## Run pre-commit hooks on all files
	@echo "Running pre-commit hooks..."
	@pre-commit run --all-files