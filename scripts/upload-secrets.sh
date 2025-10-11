#!/bin/bash

# Upload all secrets from .env to GitHub
set -e

REPO="Portfolio-jaime/BACKSTAGE-KIND-MIGRATION"
ENV_FILE=".env"

echo "🚀 Uploading GitHub Secrets from .env"
echo "======================================"
echo ""

# Check .env exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ .env file not found!"
    exit 1
fi

# Load .env - handle spaces properly
set -a
source $ENV_FILE
set +a

# Generate kubeconfig base64
KUBECONFIG_BASE64=$(cat ~/.kube/config | base64 | tr -d '\n')

echo "📤 Setting secrets..."
echo ""

# Set each secret
echo "$POSTGRES_HOST" | gh secret set POSTGRES_HOST --repo="$REPO"
echo "✅ POSTGRES_HOST"

echo "$POSTGRES_PORT" | gh secret set POSTGRES_PORT --repo="$REPO"
echo "✅ POSTGRES_PORT"

echo "$POSTGRES_USER" | gh secret set POSTGRES_USER --repo="$REPO"
echo "✅ POSTGRES_USER"

echo "$POSTGRES_PASSWORD" | gh secret set POSTGRES_PASSWORD --repo="$REPO"
echo "✅ POSTGRES_PASSWORD"

echo "$POSTGRES_DB" | gh secret set POSTGRES_DB --repo="$REPO"
echo "✅ POSTGRES_DB"

echo "$GITHUB_TOKEN" | gh secret set GH_TOKEN --repo="$REPO"
echo "✅ GH_TOKEN"

echo "$BACKEND_SECRET" | gh secret set BACKEND_SECRET --repo="$REPO"
echo "✅ BACKEND_SECRET"

echo "$AUTH_GITHUB_CLIENT_ID" | gh secret set AUTH_GITHUB_CLIENT_ID --repo="$REPO"
echo "✅ AUTH_GITHUB_CLIENT_ID"

echo "$AUTH_GITHUB_CLIENT_SECRET" | gh secret set AUTH_GITHUB_CLIENT_SECRET --repo="$REPO"
echo "✅ AUTH_GITHUB_CLIENT_SECRET"

echo "$ARGOCD_USERNAME" | gh secret set ARGOCD_USERNAME --repo="$REPO"
echo "✅ ARGOCD_USERNAME"

echo "$ARGOCD_PASSWORD" | gh secret set ARGOCD_PASSWORD --repo="$REPO"
echo "✅ ARGOCD_PASSWORD"

echo "$ARGOCD_AUTH_TOKEN" | gh secret set ARGOCD_AUTH_TOKEN --repo="$REPO"
echo "✅ ARGOCD_AUTH_TOKEN"

echo "$KUBECONFIG_BASE64" | gh secret set KUBECONFIG_DEV --repo="$REPO"
echo "✅ KUBECONFIG_DEV"

echo "$DOCKERHUB_USERNAME" | gh secret set DOCKERHUB_USERNAME --repo="$REPO"
echo "✅ DOCKERHUB_USERNAME"

echo "$DOCKERHUB_TOKEN" | gh secret set DOCKERHUB_TOKEN --repo="$REPO"
echo "✅ DOCKERHUB_TOKEN"

# Production secrets (using same values as dev for Kind cluster)
echo "$POSTGRES_HOST" | gh secret set POSTGRES_HOST_PROD --repo="$REPO"
echo "✅ POSTGRES_HOST_PROD"

echo "$POSTGRES_PASSWORD" | gh secret set POSTGRES_PASSWORD_PROD --repo="$REPO"
echo "✅ POSTGRES_PASSWORD_PROD"

echo "$AUTH_GITHUB_CLIENT_ID" | gh secret set AUTH_GITHUB_CLIENT_ID_PROD --repo="$REPO"
echo "✅ AUTH_GITHUB_CLIENT_ID_PROD"

echo "$AUTH_GITHUB_CLIENT_SECRET" | gh secret set AUTH_GITHUB_CLIENT_SECRET_PROD --repo="$REPO"
echo "✅ AUTH_GITHUB_CLIENT_SECRET_PROD"

echo "$BACKEND_SECRET" | gh secret set BACKEND_SECRET_PROD --repo="$REPO"
echo "✅ BACKEND_SECRET_PROD"

echo "$ARGOCD_PASSWORD" | gh secret set ARGOCD_PASSWORD_PROD --repo="$REPO"
echo "✅ ARGOCD_PASSWORD_PROD"

echo "$ARGOCD_AUTH_TOKEN" | gh secret set ARGOCD_AUTH_TOKEN_PROD --repo="$REPO"
echo "✅ ARGOCD_AUTH_TOKEN_PROD"

echo ""
echo "✅ All secrets uploaded successfully!"
echo ""
echo "🔍 Verify at: https://github.com/$REPO/settings/secrets/actions"
echo ""
echo "🚀 Trigger CI/CD by pushing to develop:"
echo "   git push origin develop"
echo ""
