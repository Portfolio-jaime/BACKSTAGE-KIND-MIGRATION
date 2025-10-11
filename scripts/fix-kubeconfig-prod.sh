#!/bin/bash

# Fix KUBECONFIG_PROD secret
set -e

REPO="Portfolio-jaime/BACKSTAGE-KIND-MIGRATION"

echo "🔧 Fixing KUBECONFIG_PROD secret"
echo "================================"
echo ""

# Generate clean kubeconfig base64 (single line, no newlines)
echo "📝 Generating clean kubeconfig..."
KUBECONFIG_CLEAN=$(cat ~/.kube/config | base64 | tr -d '\n\r\t ' | tr -d '[:space:]')

echo "✅ Generated clean kubeconfig"
echo "📊 Length: ${#KUBECONFIG_CLEAN} characters"
echo ""

# Verify it's valid base64
echo "🔍 Verifying base64 validity..."
if echo "$KUBECONFIG_CLEAN" | base64 -d > /dev/null 2>&1; then
    echo "✅ Base64 is valid"
else
    echo "❌ Base64 is invalid!"
    exit 1
fi
echo ""

# Upload to GitHub
echo "📤 Uploading to GitHub..."
echo "$KUBECONFIG_CLEAN" | gh secret set KUBECONFIG_PROD --repo="$REPO"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ KUBECONFIG_PROD updated successfully!"
    echo ""
    echo "🧪 Testing by triggering a new workflow..."
    echo ""
else
    echo ""
    echo "❌ Failed to update secret"
    exit 1
fi
