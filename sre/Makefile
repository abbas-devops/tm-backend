# Makefile for local testing

# Variables
APP_NAME := interview-backend
DOCKER_IMAGE := interview
DOCKER_TAG := local-$(shell git rev-parse --short HEAD)
HELM_RELEASE_NAME := interview
HELM_CHART_PATH := helm
HELM_VALUES := $(HELM_CHART_PATH)/values-prod.yaml
HELM_NAMESPACE := developers-interview-local
BACKEND_DIR := ../backend
CONTAINER_PORT := 8080
HOST_PORT := 8080

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help
help: ## list available cmds
	@echo "$(GREEN)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'

### Docker Commands

.PHONY: docker-build
docker-build: ## Build Docker image locally
	@echo "$(GREEN)Building Docker image...$(NC)"
	cd $(BACKEND_DIR) && docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) -t $(DOCKER_IMAGE):latest .
	@echo "$(GREEN)✓ Docker image built: $(DOCKER_IMAGE):$(DOCKER_TAG)$(NC)"

.PHONY: docker-run
docker-run: ## Run Docker container locally (detached)
	@echo "$(GREEN)Starting Docker container...$(NC)"
	docker run -d --name $(APP_NAME) -p $(HOST_PORT):$(CONTAINER_PORT) $(DOCKER_IMAGE):latest
	@echo "$(GREEN)✓ Container started at http://localhost:$(HOST_PORT)$(NC)"
	@echo "$(YELLOW)Test the endpoint: make docker-test$(NC)"

.PHONY: docker-test
docker-test: ## Test the /api/welcome endpoint locally
	@echo "$(GREEN)Testing /api/welcome endpoint...$(NC)"
	@sleep 5 # Wait for container to be ready
	@curl -f http://localhost:$(HOST_PORT)/api/welcome && echo "\n$(GREEN)✓ Endpoint test passed!$(NC)" || echo "$(RED)✗ Endpoint test failed!$(NC)"

.PHONY: docker-logs
docker-logs: ## Show Docker container logs
	docker logs -f $(APP_NAME)

.PHONY: docker-stop
docker-stop: ## Stop and remove Docker container
	@echo "$(YELLOW)Stopping Docker container...$(NC)"
	docker stop $(APP_NAME) || true
	docker rm $(APP_NAME) || true
	@echo "$(GREEN)✓ Container stopped$(NC)"

.PHONY: docker-clean
docker-clean: docker-stop ## Clean up Docker images and containers
	@echo "$(YELLOW)Cleaning up Docker resources...$(NC)"
	docker rmi $(DOCKER_IMAGE):$(DOCKER_TAG) $(DOCKER_IMAGE):latest || true
	@echo "$(GREEN)✓ Docker cleanup complete$(NC)"

### Helm Commands

.PHONY: helm-lint
helm-lint: ## Lint Helm chart
	@echo "$(GREEN)Linting Helm chart...$(NC)"
	helm lint $(HELM_CHART_PATH) --values $(HELM_VALUES)
	@echo "$(GREEN)✓ Helm lint passed!$(NC)"

.PHONY: helm-template
helm-template: ## Render Helm templates locally
	@echo "$(GREEN)Rendering Helm templates...$(NC)"
	helm template $(HELM_RELEASE_NAME) $(HELM_CHART_PATH) --values $(HELM_VALUES) --namespace $(HELM_NAMESPACE)

.PHONY: helm-dry-run
helm-dry-run: ## Perform Helm dry-run (requires kubectl context)
	@echo "$(GREEN)Performing Helm dry-run...$(NC)"
	@echo "$(YELLOW)Note: Using namespace '$(HELM_NAMESPACE)' to avoid conflicts with ArgoCD deployment$(NC)"
	helm upgrade --install $(HELM_RELEASE_NAME) $(HELM_CHART_PATH) \
		--values $(HELM_VALUES) \
		--namespace $(HELM_NAMESPACE) \
		--create-namespace \
		--dry-run --debug

.PHONY: helm-validate
helm-validate: helm-lint helm-template ## Validate Helm chart (lint + template)
	@echo "$(GREEN)✓ Helm chart validation complete!$(NC)"

.PHONY: helm-diff
helm-diff: ## Show diff of what would change (requires helm-diff plugin)
	@echo "$(GREEN)Showing Helm diff...$(NC)"
	@if helm plugin list | grep -q diff; then \
		helm diff upgrade $(HELM_RELEASE_NAME) $(HELM_CHART_PATH) \
			--values $(HELM_VALUES) \
			--namespace $(HELM_NAMESPACE); \
	else \
		echo "$(YELLOW)helm-diff plugin not installed. Install with: helm plugin install https://github.com/databus23/helm-diff$(NC)"; \
	fi

### Combined Workflows

.PHONY: build-and-test
build-and-test: docker-build docker-run docker-test docker-stop ## Build Docker image, run container, test endpoint, and cleanup
	@echo "$(GREEN)✓ Build and test workflow complete!$(NC)"

.PHONY: local-deploy
local-deploy: docker-build helm-dry-run ## Build Docker image and test Helm deployment
	@echo "$(GREEN)✓ Local deployment validation complete!$(NC)"

