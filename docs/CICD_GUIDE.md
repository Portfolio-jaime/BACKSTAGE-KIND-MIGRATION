# CI/CD Pipeline Guide

## 📋 Overview

This project uses **GitHub Actions** for CI/CD, **Helm** for deployment management, and **Make** for local development workflows.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   GitHub Repository                      │
│                                                          │
│  ┌────────────┐  ┌────────────┐  ┌──────────────┐     │
│  │   Code     │  │   Helm     │  │  Kubernetes  │     │
│  │  Changes   │  │  Charts    │  │   Manifests  │     │
│  └────────────┘  └────────────┘  └──────────────┘     │
└──────────────────────┬───────────────────────────────────┘
                       │
                       │ Push/PR
                       ▼
        ┌──────────────────────────────────┐
        │      GitHub Actions              │
        │  ┌───────────────────────────┐   │
        │  │  1. Lint & Test           │   │
        │  │  2. Build Backend/Frontend│   │
        │  │  3. Build Docker Image    │   │
        │  │  4. Push to Docker Hub    │   │
        │  └───────────────────────────┘   │
        └──────────────┬────────────────────┘
                       │
        ┌──────────────┴────────────────┐
        │                               │
        ▼                               ▼
┌───────────────┐            ┌──────────────────┐
│  Development  │            │   Production     │
│  Environment  │            │   Environment    │
│               │            │                  │
│  Kind Local   │            │  Cloud K8s       │
└───────────────┘            └──────────────────┘
```

## 🔄 Workflows

### 1. **CI/CD Pipeline** (`ci-cd.yaml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Manual workflow dispatch

**Jobs:**

#### Build Job
1. Checkout code
2. Setup Node.js 20
3. Install dependencies
4. Run linter
5. Run tests
6. Build backend
7. Build frontend
8. Build and push Docker image

#### Deploy to Development
- Triggered on: `develop` branch or PRs
- Environment: `development`
- Steps:
  1. Setup kubectl and Helm
  2. Configure kubeconfig
  3. Apply secrets and configmap
  4. Deploy with Helm
  5. Verify deployment

#### Deploy to Production
- Triggered on: `main` branch
- Environment: `production`
- Steps:
  1. Setup kubectl and Helm
  2. Configure kubeconfig
  3. Apply secrets and configmap
  4. Deploy with Helm
  5. Verify deployment
  6. Run smoke tests

### 2. **PR Checks** (`pr-checks.yaml`)

**Triggers:**
- Pull requests (opened, synchronize, reopened)

**Jobs:**
- Lint and Test
- Build Check
- Helm Chart Validation
- Docker Build Test (no push)

## 🔐 Required Secrets

### GitHub Secrets Configuration

Navigate to: **Settings → Secrets and variables → Actions**

#### Docker Hub
```
DOCKERHUB_USERNAME: your-dockerhub-username
DOCKERHUB_TOKEN: your-dockerhub-token
```

#### Kubernetes (Development)
```
KUBECONFIG_DEV: base64-encoded kubeconfig for dev cluster
```

#### Kubernetes (Production)
```
KUBECONFIG_PROD: base64-encoded kubeconfig for prod cluster
```

#### Database (Development)
```
POSTGRES_HOST: psql-postgresql.backstage.svc.cluster.local
POSTGRES_PORT: 5432
POSTGRES_USER: backstage
POSTGRES_PASSWORD: your-dev-password
POSTGRES_DB: backstage
```

#### Database (Production)
```
POSTGRES_HOST_PROD: your-prod-postgres-host
POSTGRES_PASSWORD_PROD: your-prod-password
```

#### GitHub OAuth
```
# Development
AUTH_GITHUB_CLIENT_ID: your-dev-oauth-client-id
AUTH_GITHUB_CLIENT_SECRET: your-dev-oauth-secret

# Production
AUTH_GITHUB_CLIENT_ID_PROD: your-prod-oauth-client-id
AUTH_GITHUB_CLIENT_SECRET_PROD: your-prod-oauth-secret
```

#### GitHub Token (for integrations)
```
GH_TOKEN: your-github-personal-access-token
```

#### Backstage Backend
```
BACKEND_SECRET: your-backend-secret-key
BACKEND_SECRET_PROD: your-prod-backend-secret
```

#### ArgoCD (Optional)
```
ARGOCD_USERNAME: admin
ARGOCD_PASSWORD: your-argocd-password
ARGOCD_AUTH_TOKEN: your-argocd-token
ARGOCD_PASSWORD_PROD: your-prod-argocd-password
ARGOCD_AUTH_TOKEN_PROD: your-prod-argocd-token
```

## 🛠️ Local Development with Makefile

### Quick Reference

```bash
# Show all available commands
make help

# Install dependencies
make install-deps

# Build components
make build-backend      # Build backend only
make build-frontend     # Build frontend only
make build             # Build both

# Docker operations
make build-docker      # Build Docker image
make push-docker       # Build and push to Docker Hub
make kind-load         # Load image into Kind cluster

# Deployment
make deploy            # Deploy using kubectl
make helm-install      # Install with Helm
make helm-upgrade      # Upgrade with Helm
make helm-migrate      # Migrate kubectl deployment to Helm

# Management
make restart           # Restart Backstage deployment
make logs              # Show Backstage logs
make status            # Show deployment status

# Development
make dev               # Run in development mode
make quick-deploy      # Quick redeploy (no push)
make prod-deploy       # Full production deployment
```

### Common Workflows

#### 1. Local Development
```bash
# Start development server
make dev
```

#### 2. Build and Test Locally
```bash
# Build everything
make build

# Build Docker image
make build-docker

# Load into Kind
make kind-load
```

#### 3. Deploy to Local Kind
```bash
# First time: Install with Helm
make helm-install

# Updates: Upgrade with Helm
make helm-upgrade
```

#### 4. Quick Deploy (Local Changes)
```bash
# Build, load into Kind, and restart (no push to Docker Hub)
make quick-deploy
```

## 📦 Helm Chart

### Structure

```
helm/backstage/
├── Chart.yaml          # Chart metadata
├── values.yaml         # Default values
└── templates/
    ├── _helpers.tpl    # Template helpers
    ├── deployment.yaml # Deployment manifest
    ├── service.yaml    # Service manifest
    └── ingress.yaml    # Ingress manifest
```

### Install with Helm

```bash
# Install
helm install backstage ./helm/backstage \
  --namespace backstage \
  --create-namespace \
  --set image.tag=latest

# Upgrade
helm upgrade backstage ./helm/backstage \
  --namespace backstage \
  --set image.tag=v1.2.3

# Uninstall
helm uninstall backstage -n backstage
```

### Override Values

Create a `values-override.yaml`:

```yaml
image:
  tag: custom-tag

ingress:
  host: custom-host.example.com
  tls:
    enabled: true

resources:
  limits:
    memory: 4Gi
    cpu: 2000m
```

Deploy with overrides:

```bash
helm upgrade backstage ./helm/backstage \
  -f values-override.yaml \
  --namespace backstage
```

## 🔄 Git Workflow

### Branch Strategy

- `main` → Production deployments
- `develop` → Development deployments
- `feature/*` → Feature branches (create PRs)
- `fix/*` → Bug fix branches (create PRs)

### Deployment Flow

```
1. Create feature branch
   git checkout -b feature/my-feature

2. Make changes and commit
   git add .
   git commit -m "feat: add new feature"

3. Push and create PR
   git push origin feature/my-feature

4. PR Checks run automatically
   - Lint & Test
   - Build Check
   - Helm Validation
   - Docker Build Test

5. Merge to develop
   - Auto-deploys to Development

6. Merge to main
   - Auto-deploys to Production
```

## 🧪 Testing CI/CD

### Test PR Workflow

```bash
# Create test branch
git checkout -b test/ci-pipeline

# Make a change
echo "# Test" >> README.md

# Commit and push
git commit -am "test: CI pipeline"
git push origin test/ci-pipeline

# Create PR on GitHub
# Watch PR checks run
```

### Test Development Deployment

```bash
# Push to develop branch
git checkout develop
git pull origin develop
git merge feature/my-feature
git push origin develop

# Monitor workflow in GitHub Actions
# Check deployment: kubectl get pods -n backstage
```

## 📊 Monitoring Deployments

### Check GitHub Actions

1. Go to **Actions** tab in GitHub
2. Select workflow run
3. View job logs

### Check Kubernetes Deployment

```bash
# Check pods
kubectl get pods -n backstage

# Check deployment status
kubectl rollout status deployment/backstage -n backstage

# View logs
kubectl logs -f deployment/backstage -n backstage

# Check Helm release
helm list -n backstage

# Get release history
helm history backstage -n backstage
```

## 🚨 Troubleshooting

### Build Failures

```bash
# Check GitHub Actions logs
# Reproduce locally:
cd backstage-kind
yarn install
yarn workspace backend build
yarn workspace app build
```

### Deployment Failures

```bash
# Check pod status
kubectl describe pod <pod-name> -n backstage

# Check events
kubectl get events -n backstage --sort-by='.lastTimestamp'

# Check secrets
kubectl get secret backstage-secrets -n backstage -o yaml

# Rollback with Helm
helm rollback backstage <revision> -n backstage
```

### Image Not Pulling

```bash
# Verify image exists
docker pull jaimehenao8126/backstage-production:latest

# Check image pull secrets
kubectl describe deployment backstage -n backstage

# Force pull
kubectl delete pod -n backstage -l app=backstage
```

## 🔄 Rollback Procedures

### Helm Rollback

```bash
# List revisions
helm history backstage -n backstage

# Rollback to previous
helm rollback backstage -n backstage

# Rollback to specific revision
helm rollback backstage 3 -n backstage
```

### Manual Rollback

```bash
# Use previous image tag
kubectl set image deployment/backstage \
  backstage=jaimehenao8126/backstage-production:previous-tag \
  -n backstage

# Or use Makefile
make restart
```

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Helm Documentation](https://helm.sh/docs/)
- [Backstage Documentation](https://backstage.io/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

**Last Updated:** October 10, 2025
**Maintainer:** Jaime Henao <jaime.andres.henao.arbelaez@ba.com>
