#!/bin/bash

# Setup GitHub Secrets from .env file
# Usage: ./scripts/setup-secrets-from-env.sh

set -e

REPO="Portfolio-jaime/BACKSTAGE-KIND-MIGRATION"
ENV_FILE=".env"

echo "🔐 Setting up GitHub Secrets from .env file"
echo "Repository: $REPO"
echo ""

# Check if .env exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ .env file not found!"
    exit 1
fi

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

echo "✅ GitHub CLI is authenticated"
echo ""

# Load .env file
source $ENV_FILE

echo "📦 Setting up secrets..."
echo ""

# PostgreSQL
echo "Setting POSTGRES_HOST..."
echo "$POSTGRES_HOST" | gh secret set POSTGRES_HOST --repo="$REPO"

echo "Setting POSTGRES_PORT..."
echo "$POSTGRES_PORT" | gh secret set POSTGRES_PORT --repo="$REPO"

echo "Setting POSTGRES_USER..."
echo "$POSTGRES_USER" | gh secret set POSTGRES_USER --repo="$REPO"

echo "Setting POSTGRES_PASSWORD..."
echo "$POSTGRES_PASSWORD" | gh secret set POSTGRES_PASSWORD --repo="$REPO"

echo "Setting POSTGRES_DB..."
echo "$POSTGRES_DB" | gh secret set POSTGRES_DB --repo="$REPO"

# GitHub Token
echo "Setting GH_TOKEN..."
echo "$GITHUB_TOKEN" | gh secret set GH_TOKEN --repo="$REPO"

# Backend Secret
echo "Setting BACKEND_SECRET..."
echo "$BACKEND_SECRET" | gh secret set BACKEND_SECRET --repo="$REPO"

# GitHub OAuth
echo "Setting AUTH_GITHUB_CLIENT_ID..."
echo "$AUTH_GITHUB_CLIENT_ID" | gh secret set AUTH_GITHUB_CLIENT_ID --repo="$REPO"

echo "Setting AUTH_GITHUB_CLIENT_SECRET..."
echo "$AUTH_GITHUB_CLIENT_SECRET" | gh secret set AUTH_GITHUB_CLIENT_SECRET --repo="$REPO"

# ArgoCD (Optional)
echo "Setting ARGOCD_USERNAME..."
echo "$ARGOCD_USERNAME" | gh secret set ARGOCD_USERNAME --repo="$REPO"

echo "Setting ARGOCD_PASSWORD..."
echo "$ARGOCD_PASSWORD" | gh secret set ARGOCD_PASSWORD --repo="$REPO"

echo "Setting ARGOCD_AUTH_TOKEN..."
echo "$ARGOCD_AUTH_TOKEN" | gh secret set ARGOCD_AUTH_TOKEN --repo="$REPO"

# Kubeconfig (base64 encoded)
echo "Setting KUBECONFIG_DEV..."
cat ~/.kube/config | base64 | tr -d '\n' | gh secret set KUBECONFIG_DEV --repo="$REPO"

echo ""
echo "✅ All secrets have been configured successfully!"
echo ""
echo "⚠️  IMPORTANT: You still need to configure Docker Hub credentials:"
echo ""
echo "   echo 'YOUR_DOCKERHUB_USERNAME' | gh secret set DOCKERHUB_USERNAME --repo=$REPO"
echo "   echo 'YOUR_DOCKERHUB_TOKEN' | gh secret set DOCKERHUB_TOKEN --repo=$REPO"
echo ""
echo "Create Docker Hub token at: https://hub.docker.com/settings/security"
echo ""
echo "Verify secrets at:"
echo "  https://github.com/$REPO/settings/secrets/actions"
echo ""
