#!/bin/bash

# Setup GitHub Secrets for CI/CD
# Usage: ./scripts/setup-github-secrets.sh <github-repo>
# Example: ./scripts/setup-github-secrets.sh username/backstage-kind-migration

set -e

REPO=$1

if [ -z "$REPO" ]; then
    echo "Usage: $0 <github-repo>"
    echo "Example: $0 username/backstage-kind-migration"
    exit 1
fi

echo "🔐 Setting up GitHub Secrets for repository: $REPO"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo "Install it from: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI"
    echo "Run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"
echo ""

# Function to set secret
set_secret() {
    local secret_name=$1
    local secret_value=$2
    local description=$3

    if [ -z "$secret_value" ]; then
        echo "⏭️  Skipping $secret_name (no value provided)"
        return
    fi

    echo "Setting $secret_name... ($description)"
    echo "$secret_value" | gh secret set "$secret_name" --repo="$REPO"
}

# Docker Hub Credentials
echo "📦 Docker Hub Credentials"
echo "=========================="
read -p "Docker Hub Username: " DOCKERHUB_USERNAME
read -sp "Docker Hub Token: " DOCKERHUB_TOKEN
echo ""

set_secret "DOCKERHUB_USERNAME" "$DOCKERHUB_USERNAME" "Docker Hub username"
set_secret "DOCKERHUB_TOKEN" "$DOCKERHUB_TOKEN" "Docker Hub access token"
echo ""

# Kubernetes Config (Development)
echo "☸️  Kubernetes Config - Development"
echo "====================================="
echo "Encode your kubeconfig:"
echo "  cat ~/.kube/config | base64"
read -p "Enter base64-encoded kubeconfig for DEV: " KUBECONFIG_DEV
set_secret "KUBECONFIG_DEV" "$KUBECONFIG_DEV" "Development kubeconfig"
echo ""

# Kubernetes Config (Production - Optional)
echo "☸️  Kubernetes Config - Production (Optional)"
echo "=============================================="
read -p "Enter base64-encoded kubeconfig for PROD (or press Enter to skip): " KUBECONFIG_PROD
set_secret "KUBECONFIG_PROD" "$KUBECONFIG_PROD" "Production kubeconfig"
echo ""

# Database Secrets - Development
echo "🗄️  Database Secrets - Development"
echo "==================================="
read -p "PostgreSQL Host (DEV) [psql-postgresql.backstage.svc.cluster.local]: " POSTGRES_HOST
POSTGRES_HOST=${POSTGRES_HOST:-psql-postgresql.backstage.svc.cluster.local}

read -p "PostgreSQL Port [5432]: " POSTGRES_PORT
POSTGRES_PORT=${POSTGRES_PORT:-5432}

read -p "PostgreSQL User [backstage]: " POSTGRES_USER
POSTGRES_USER=${POSTGRES_USER:-backstage}

read -sp "PostgreSQL Password (DEV): " POSTGRES_PASSWORD
echo ""

read -p "PostgreSQL Database [backstage]: " POSTGRES_DB
POSTGRES_DB=${POSTGRES_DB:-backstage}

set_secret "POSTGRES_HOST" "$POSTGRES_HOST" "PostgreSQL host"
set_secret "POSTGRES_PORT" "$POSTGRES_PORT" "PostgreSQL port"
set_secret "POSTGRES_USER" "$POSTGRES_USER" "PostgreSQL user"
set_secret "POSTGRES_PASSWORD" "$POSTGRES_PASSWORD" "PostgreSQL password (dev)"
set_secret "POSTGRES_DB" "$POSTGRES_DB" "PostgreSQL database"
echo ""

# Database Secrets - Production (Optional)
echo "🗄️  Database Secrets - Production (Optional)"
echo "=============================================="
read -p "PostgreSQL Host (PROD) [or press Enter to skip]: " POSTGRES_HOST_PROD
read -sp "PostgreSQL Password (PROD) [or press Enter to skip]: " POSTGRES_PASSWORD_PROD
echo ""

set_secret "POSTGRES_HOST_PROD" "$POSTGRES_HOST_PROD" "PostgreSQL host (prod)"
set_secret "POSTGRES_PASSWORD_PROD" "$POSTGRES_PASSWORD_PROD" "PostgreSQL password (prod)"
echo ""

# GitHub OAuth - Development
echo "🔑 GitHub OAuth - Development"
echo "=============================="
echo "Create OAuth App at: https://github.com/settings/developers"
read -p "GitHub OAuth Client ID (DEV): " AUTH_GITHUB_CLIENT_ID
read -sp "GitHub OAuth Client Secret (DEV): " AUTH_GITHUB_CLIENT_SECRET
echo ""

set_secret "AUTH_GITHUB_CLIENT_ID" "$AUTH_GITHUB_CLIENT_ID" "GitHub OAuth client ID (dev)"
set_secret "AUTH_GITHUB_CLIENT_SECRET" "$AUTH_GITHUB_CLIENT_SECRET" "GitHub OAuth client secret (dev)"
echo ""

# GitHub OAuth - Production (Optional)
echo "🔑 GitHub OAuth - Production (Optional)"
echo "========================================"
read -p "GitHub OAuth Client ID (PROD) [or press Enter to skip]: " AUTH_GITHUB_CLIENT_ID_PROD
read -sp "GitHub OAuth Client Secret (PROD) [or press Enter to skip]: " AUTH_GITHUB_CLIENT_SECRET_PROD
echo ""

set_secret "AUTH_GITHUB_CLIENT_ID_PROD" "$AUTH_GITHUB_CLIENT_ID_PROD" "GitHub OAuth client ID (prod)"
set_secret "AUTH_GITHUB_CLIENT_SECRET_PROD" "$AUTH_GITHUB_CLIENT_SECRET_PROD" "GitHub OAuth client secret (prod)"
echo ""

# GitHub Personal Access Token
echo "🔐 GitHub Personal Access Token"
echo "================================"
echo "Create token at: https://github.com/settings/tokens/new"
echo "Required scopes: repo, read:org, read:user, user:email"
read -sp "GitHub Personal Access Token: " GH_TOKEN
echo ""

set_secret "GH_TOKEN" "$GH_TOKEN" "GitHub personal access token"
echo ""

# Backstage Backend Secret
echo "🔒 Backstage Backend Secret"
echo "==========================="
echo "Generate with: openssl rand -hex 32"
read -p "Backend Secret (DEV): " BACKEND_SECRET
read -p "Backend Secret (PROD) [or press Enter to skip]: " BACKEND_SECRET_PROD

set_secret "BACKEND_SECRET" "$BACKEND_SECRET" "Backend secret (dev)"
set_secret "BACKEND_SECRET_PROD" "$BACKEND_SECRET_PROD" "Backend secret (prod)"
echo ""

# ArgoCD Secrets (Optional)
echo "🚀 ArgoCD Secrets (Optional)"
echo "============================"
read -p "ArgoCD Username [admin]: " ARGOCD_USERNAME
ARGOCD_USERNAME=${ARGOCD_USERNAME:-admin}

read -sp "ArgoCD Password (DEV) [or press Enter to skip]: " ARGOCD_PASSWORD
echo ""

read -p "ArgoCD Auth Token (DEV) [or press Enter to skip]: " ARGOCD_AUTH_TOKEN

read -sp "ArgoCD Password (PROD) [or press Enter to skip]: " ARGOCD_PASSWORD_PROD
echo ""

read -p "ArgoCD Auth Token (PROD) [or press Enter to skip]: " ARGOCD_AUTH_TOKEN_PROD

set_secret "ARGOCD_USERNAME" "$ARGOCD_USERNAME" "ArgoCD username"
set_secret "ARGOCD_PASSWORD" "$ARGOCD_PASSWORD" "ArgoCD password (dev)"
set_secret "ARGOCD_AUTH_TOKEN" "$ARGOCD_AUTH_TOKEN" "ArgoCD token (dev)"
set_secret "ARGOCD_PASSWORD_PROD" "$ARGOCD_PASSWORD_PROD" "ArgoCD password (prod)"
set_secret "ARGOCD_AUTH_TOKEN_PROD" "$ARGOCD_AUTH_TOKEN_PROD" "ArgoCD token (prod)"
echo ""

echo "✅ All secrets have been set up successfully!"
echo ""
echo "You can verify secrets at:"
echo "  https://github.com/$REPO/settings/secrets/actions"
echo ""
echo "Next steps:"
echo "  1. Review the secrets in GitHub"
echo "  2. Push code to trigger CI/CD pipeline"
echo "  3. Monitor workflow at: https://github.com/$REPO/actions"
