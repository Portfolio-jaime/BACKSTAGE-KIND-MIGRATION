.PHONY: help build-backend build-frontend build-docker push-docker deploy clean restart logs port-forward helm-install helm-upgrade helm-uninstall postgres-rollout kind-load

# Variables
DOCKER_IMAGE := jaimehenao8126/backstage-production
DOCKER_TAG := $(shell git rev-parse --short HEAD 2>/dev/null || echo "latest")
NAMESPACE := backstage
HELM_RELEASE := backstage
PROJECT_DIR := $(CURDIR)/backstage-kind

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

build-backend: ## Build backend locally
	@echo "Building backend..."
	@cd $(PROJECT_DIR) && export TMPDIR=/tmp && yarn workspace backend build

build-frontend: ## Build frontend locally
	@echo "Building frontend..."
	@cd $(PROJECT_DIR) && export TMPDIR=/tmp && yarn workspace app build

build: build-backend build-frontend ## Build both backend and frontend

build-docker: build ## Build Docker image
	@echo "Building Docker image $(DOCKER_IMAGE):$(DOCKER_TAG)..."
	@cd $(PROJECT_DIR) && docker build -f Dockerfile.kind -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	@docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(DOCKER_IMAGE):latest
	@echo "Docker image built successfully!"

push-docker: build-docker ## Build and push Docker image to DockerHub
	@echo "Pushing $(DOCKER_IMAGE):$(DOCKER_TAG) to DockerHub..."
	@docker push $(DOCKER_IMAGE):$(DOCKER_TAG)
	@docker push $(DOCKER_IMAGE):latest
	@echo "Docker image pushed successfully!"

kind-load: build-docker ## Load Docker image into Kind cluster
	@echo "Loading image into Kind cluster..."
	@export TMPDIR=/tmp && kind load docker-image $(DOCKER_IMAGE):$(DOCKER_TAG) --name kind || true
	@echo "Image loaded into Kind cluster!"

deploy: push-docker ## Build, push and deploy to Kubernetes
	@echo "Deploying to Kubernetes..."
	@kubectl apply -f kubernetes/namespace.yaml
	@kubectl apply -f kubernetes/rbac.yaml
	@kubectl apply -f kubernetes/configmap.yaml
	@kubectl apply -f kubernetes/secrets.yaml
	@kubectl apply -f kubernetes/service.yaml
	@kubectl apply -f kubernetes/deployment.yaml
	@kubectl apply -f kubernetes/ingress.yaml
	@echo "Deployment complete!"

helm-install: build-docker ## Install Backstage using Helm
	@echo "Installing Backstage using Helm..."
	@kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	@helm install $(HELM_RELEASE) helm/backstage -n $(NAMESPACE) \
		--set image.tag=$(DOCKER_TAG) \
		--wait --timeout 10m
	@echo "Helm installation complete!"

helm-upgrade: build-docker ## Upgrade Backstage using Helm
	@echo "Upgrading Backstage using Helm..."
	@helm upgrade $(HELM_RELEASE) helm/backstage -n $(NAMESPACE) \
		--set image.tag=$(DOCKER_TAG) \
		--wait --timeout 10m
	@echo "Helm upgrade complete!"

helm-uninstall: ## Uninstall Backstage Helm release
	@echo "Uninstalling Backstage..."
	@helm uninstall $(HELM_RELEASE) -n $(NAMESPACE)
	@echo "Helm uninstall complete!"

postgres-rollout: ## Rollout restart PostgreSQL
	@echo "Rolling out PostgreSQL..."
	@kubectl rollout restart statefulset/psql-postgresql -n $(NAMESPACE)
	@kubectl rollout status statefulset/psql-postgresql -n $(NAMESPACE) --timeout=5m
	@echo "PostgreSQL rollout complete!"

restart: ## Restart Backstage deployment
	@echo "Restarting Backstage deployment..."
	@kubectl rollout restart deployment/backstage -n $(NAMESPACE)
	@kubectl rollout status deployment/backstage -n $(NAMESPACE) --timeout=5m
	@echo "Restart complete!"

clean: ## Clean local build artifacts
	@echo "Cleaning build artifacts..."
	@rm -rf $(PROJECT_DIR)/packages/app/dist
	@rm -rf $(PROJECT_DIR)/packages/backend/dist
	@rm -rf $(PROJECT_DIR)/node_modules/.cache
	@echo "Clean complete!"

logs: ## Show Backstage logs
	@kubectl logs -f -n $(NAMESPACE) -l app=backstage --tail=100

logs-postgres: ## Show PostgreSQL logs
	@kubectl logs -f -n $(NAMESPACE) statefulset/psql-postgresql --tail=100

port-forward: ## Port-forward Backstage service to localhost:7007
	@echo "Port-forwarding to localhost:7007..."
	@kubectl port-forward -n $(NAMESPACE) svc/backstage 7007:80

status: ## Show deployment status
	@echo "Namespace: $(NAMESPACE)"
	@echo "\nPods:"
	@kubectl get pods -n $(NAMESPACE)
	@echo "\nServices:"
	@kubectl get svc -n $(NAMESPACE)
	@echo "\nIngresses:"
	@kubectl get ingress -n $(NAMESPACE)

describe: ## Describe Backstage resources
	@kubectl describe deployment/backstage -n $(NAMESPACE)
	@kubectl describe svc/backstage -n $(NAMESPACE)

test: ## Test Backstage health endpoint
	@echo "Testing Backstage health..."
	@kubectl run curl-test --image=curlimages/curl:latest --rm -i --restart=Never -n $(NAMESPACE) -- \
		curl -f http://backstage.$(NAMESPACE).svc.cluster.local/healthcheck

install-deps: ## Install yarn dependencies
	@echo "Installing dependencies..."
	@cd $(PROJECT_DIR) && export TMPDIR=/tmp && yarn install
	@echo "Dependencies installed!"

dev: ## Run Backstage in development mode
	@echo "Starting Backstage in development mode..."
	@cd $(PROJECT_DIR) && export TMPDIR=/tmp && yarn dev

# Quick development workflow
quick-deploy: build-backend build-frontend build-docker restart ## Quick redeploy (no push)
	@echo "Quick deployment complete!"

# Full production workflow
prod-deploy: push-docker helm-upgrade ## Full production deployment with Helm
	@echo "Production deployment complete!"
