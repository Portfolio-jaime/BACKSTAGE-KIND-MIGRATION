#!/bin/bash

# Automated GitHub Secrets Setup
# This script will configure all GitHub secrets automatically

set -e

REPO="Portfolio-jaime/BACKSTAGE-KIND-MIGRATION"
ENV_FILE=".env"

echo "🤖 Automated GitHub Secrets Setup"
echo "=================================="
echo ""

# Check if .env exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ .env file not found!"
    exit 1
fi

# Load .env
source $ENV_FILE

# Generate kubeconfig base64
KUBECONFIG_BASE64=$(cat ~/.kube/config | base64 | tr -d '\n')

# Ask for Docker Hub credentials
echo "📦 Docker Hub Credentials"
echo "========================="
read -p "Docker Hub Username [jaimehenao8126]: " DOCKERHUB_USERNAME
DOCKERHUB_USERNAME=${DOCKERHUB_USERNAME:-jaimehenao8126}

read -sp "Docker Hub Token (from https://hub.docker.com/settings/security): " DOCKERHUB_TOKEN
echo ""
echo ""

if [ -z "$DOCKERHUB_TOKEN" ]; then
    echo "❌ Docker Hub token is required!"
    exit 1
fi

# Re-authenticate with gh (with admin:org scope)
echo "🔐 Authenticating with GitHub..."
echo "Please authenticate with these scopes: repo, admin:org, write:packages"
gh auth login --scopes "repo,admin:org,write:packages" --web

echo ""
echo "✅ Authentication complete"
echo ""

# Set all secrets
echo "📤 Uploading secrets to GitHub..."
echo ""

echo "Setting POSTGRES_HOST..."
echo "$POSTGRES_HOST" | gh secret set POSTGRES_HOST --repo="$REPO" 2>/dev/null || echo "⚠️  Failed to set POSTGRES_HOST"

echo "Setting POSTGRES_PORT..."
echo "$POSTGRES_PORT" | gh secret set POSTGRES_PORT --repo="$REPO" 2>/dev/null || echo "⚠️  Failed to set POSTGRES_PORT"

echo "Setting POSTGRES_USER..."
echo "$POSTGRES_USER" | gh secret set POSTGRES_USER --repo="$REPO" 2>/dev/null || echo "⚠️  Failed to set POSTGRES_USER"

echo "Setting POSTGRES_PASSWORD..."
echo "$POSTGRES_PASSWORD" | gh secret set POSTGRES_PASSWORD --repo="$REPO" 2>/dev/null || echo "⚠️  Failed to set POSTGRES_PASSWORD"

echo "Setting POSTGRES_DB..."
echo "$POSTGRES_DB" | gh secret set POSTGRES_DB --repo="$REPO" 2>/dev/null || echo "⚠️  Failed to set POSTGRES_DB"

echo "Setting GH_TOKEN..."
echo "$GITHUB_TOKEN" | gh secret set GH_TOKEN --repo="$REPO" 2>/dev/null || echo "⚠️  Failed to set GH_TOKEN"

echo "Setting BACKEND_SECRET..."
echo "$BACKEND_SECRET" | gh secret set BACKEND_SECRET --repo="$REPO" 2>/dev/null || echo "⚠️  Failed to set BACKEND_SECRET"

echo "Setting AUTH_GITHUB_CLIENT_ID..."
echo "$AUTH_GITHUB_CLIENT_ID" | gh secret set AUTH_GITHUB_CLIENT_ID --repo="$REPO" 2>/dev/null || echo "⚠️  Failed to set AUTH_GITHUB_CLIENT_ID"

echo "Setting AUTH_GITHUB_CLIENT_SECRET..."
echo "$AUTH_GITHUB_CLIENT_SECRET" | gh secret set AUTH_GITHUB_CLIENT_SECRET --repo="$REPO" 2>/dev/null || echo "⚠️  Failed to set AUTH_GITHUB_CLIENT_SECRET"

echo "Setting ARGOCD_USERNAME..."
echo "$ARGOCD_USERNAME" | gh secret set ARGOCD_USERNAME --repo="$REPO" 2>/dev/null || echo "⚠️  Failed to set ARGOCD_USERNAME"

echo "Setting ARGOCD_PASSWORD..."
echo "$ARGOCD_PASSWORD" | gh secret set ARGOCD_PASSWORD --repo="$REPO" 2>/dev/null || echo "⚠️  Failed to set ARGOCD_PASSWORD"

echo "Setting ARGOCD_AUTH_TOKEN..."
echo "$ARGOCD_AUTH_TOKEN" | gh secret set ARGOCD_AUTH_TOKEN --repo="$REPO" 2>/dev/null || echo "⚠️  Failed to set ARGOCD_AUTH_TOKEN"

echo "Setting KUBECONFIG_DEV..."
echo "$KUBECONFIG_BASE64" | gh secret set KUBECONFIG_DEV --repo="$REPO" 2>/dev/null || echo "⚠️  Failed to set KUBECONFIG_DEV"

echo "Setting DOCKERHUB_USERNAME..."
echo "$DOCKERHUB_USERNAME" | gh secret set DOCKERHUB_USERNAME --repo="$REPO" 2>/dev/null || echo "⚠️  Failed to set DOCKERHUB_USERNAME"

echo "Setting DOCKERHUB_TOKEN..."
echo "$DOCKERHUB_TOKEN" | gh secret set DOCKERHUB_TOKEN --repo="$REPO" 2>/dev/null || echo "⚠️  Failed to set DOCKERHUB_TOKEN"

echo ""
echo "✅ All secrets configured!"
echo ""
echo "Verify at: https://github.com/$REPO/settings/secrets/actions"
echo ""
echo "🚀 Next steps:"
echo "   1. Go to: https://github.com/$REPO/actions"
echo "   2. The CI/CD workflow should trigger automatically"
echo "   3. Monitor the build and deployment"
echo ""
