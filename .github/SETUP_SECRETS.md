# GitHub Secrets Setup Guide

## Quick Setup

Run the automated script:

```bash
chmod +x scripts/setup-github-secrets.sh
./scripts/setup-github-secrets.sh your-username/backstage-kind-migration
```

## Manual Setup

Go to: **Settings → Secrets and variables → Actions → New repository secret**

### Required Secrets

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `DOCKERHUB_USERNAME` | Docker Hub username | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token | [Create at Docker Hub](https://hub.docker.com/settings/security) |
| `KUBECONFIG_DEV` | Base64 kubeconfig (dev) | `cat ~/.kube/config \| base64` |
| `POSTGRES_HOST` | PostgreSQL host | `psql-postgresql.backstage.svc.cluster.local` |
| `POSTGRES_PORT` | PostgreSQL port | `5432` |
| `POSTGRES_USER` | PostgreSQL user | `backstage` |
| `POSTGRES_PASSWORD` | PostgreSQL password | Your DB password |
| `POSTGRES_DB` | PostgreSQL database | `backstage` |
| `AUTH_GITHUB_CLIENT_ID` | GitHub OAuth client ID | [Create OAuth App](https://github.com/settings/developers) |
| `AUTH_GITHUB_CLIENT_SECRET` | GitHub OAuth secret | From OAuth App |
| `GH_TOKEN` | GitHub PAT | [Create token](https://github.com/settings/tokens/new) |
| `BACKEND_SECRET` | Backstage backend secret | `openssl rand -hex 32` |

### Optional Secrets (Production)

| Secret Name | Description |
|-------------|-------------|
| `KUBECONFIG_PROD` | Base64 kubeconfig (prod) |
| `POSTGRES_HOST_PROD` | PostgreSQL host (prod) |
| `POSTGRES_PASSWORD_PROD` | PostgreSQL password (prod) |
| `AUTH_GITHUB_CLIENT_ID_PROD` | GitHub OAuth client ID (prod) |
| `AUTH_GITHUB_CLIENT_SECRET_PROD` | GitHub OAuth secret (prod) |
| `BACKEND_SECRET_PROD` | Backend secret (prod) |
| `ARGOCD_USERNAME` | ArgoCD username |
| `ARGOCD_PASSWORD` | ArgoCD password (dev) |
| `ARGOCD_AUTH_TOKEN` | ArgoCD token (dev) |
| `ARGOCD_PASSWORD_PROD` | ArgoCD password (prod) |
| `ARGOCD_AUTH_TOKEN_PROD` | ArgoCD token (prod) |

## Verify Setup

```bash
# List secrets (won't show values)
gh secret list --repo your-username/backstage-kind-migration
```

## Test Workflow

1. Push code to trigger workflow:
   ```bash
   git add .
   git commit -m "test: CI/CD pipeline"
   git push origin develop
   ```

2. Monitor at: https://github.com/your-username/backstage-kind-migration/actions
