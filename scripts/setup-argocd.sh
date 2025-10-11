#!/bin/bash

# Setup ArgoCD for Backstage GitOps
set -e

ARGOCD_NAMESPACE="argocd"
BACKSTAGE_NAMESPACE="backstage"

echo "🚀 Setting up ArgoCD for Backstage GitOps"
echo "=========================================="
echo ""

# Check if ArgoCD is installed
if ! kubectl get namespace $ARGOCD_NAMESPACE &> /dev/null; then
    echo "📦 Installing ArgoCD..."
    kubectl create namespace $ARGOCD_NAMESPACE
    kubectl apply -n $ARGOCD_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    echo "✅ ArgoCD installed"
else
    echo "✅ ArgoCD already installed"
fi

echo ""
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s \
    deployment/argocd-server -n $ARGOCD_NAMESPACE

echo ""
echo "🔐 Getting ArgoCD admin password..."
ARGOCD_PASSWORD=$(kubectl -n $ARGOCD_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Admin Password: $ARGOCD_PASSWORD"

echo ""
echo "🌐 Setting up ArgoCD port-forward..."
echo "Run in another terminal:"
echo "  kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE 8080:443"
echo ""
echo "Then access ArgoCD at: https://localhost:8080"
echo "  Username: admin"
echo "  Password: $ARGOCD_PASSWORD"
echo ""

# Install ArgoCD Image Updater
echo "📦 Installing ArgoCD Image Updater..."
if ! kubectl get deployment argocd-image-updater -n $ARGOCD_NAMESPACE &> /dev/null; then
    kubectl apply -n $ARGOCD_NAMESPACE -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml
    echo "✅ ArgoCD Image Updater installed"
else
    echo "✅ ArgoCD Image Updater already installed"
fi

echo ""
echo "⏳ Waiting for Image Updater to be ready..."
kubectl wait --for=condition=available --timeout=300s \
    deployment/argocd-image-updater -n $ARGOCD_NAMESPACE || true

# Apply Image Updater config
echo ""
echo "⚙️  Applying Image Updater configuration..."
kubectl apply -f argocd/image-updater-config.yaml

# Create Docker Hub secret for Image Updater
echo ""
echo "🔑 Creating Docker Hub secret..."
read -p "Docker Hub Username [jaimehenao8126]: " DOCKERHUB_USER
DOCKERHUB_USER=${DOCKERHUB_USER:-jaimehenao8126}

read -sp "Docker Hub Token: " DOCKERHUB_TOKEN
echo ""

kubectl create secret generic dockerhub-secret \
    --from-literal=username=$DOCKERHUB_USER \
    --from-literal=password=$DOCKERHUB_TOKEN \
    --namespace=$ARGOCD_NAMESPACE \
    --dry-run=client -o yaml | kubectl apply -f -

echo "✅ Docker Hub secret created"

# Apply Backstage Application
echo ""
echo "📱 Creating Backstage Application in ArgoCD..."
kubectl apply -f argocd/backstage-application.yaml

echo ""
echo "✅ ArgoCD setup complete!"
echo ""
echo "=========================================="
echo "🎉 Next steps:"
echo "=========================================="
echo ""
echo "1. Access ArgoCD UI:"
echo "   kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE 8080:443"
echo "   https://localhost:8080"
echo ""
echo "2. Login with:"
echo "   Username: admin"
echo "   Password: $ARGOCD_PASSWORD"
echo ""
echo "3. Check Backstage application status:"
echo "   kubectl get application backstage -n $ARGOCD_NAMESPACE"
echo ""
echo "4. Watch sync status:"
echo "   kubectl get application backstage -n $ARGOCD_NAMESPACE -w"
echo ""
echo "5. When CI/CD pushes a new image, ArgoCD will:"
echo "   - Detect the new image"
echo "   - Update the Helm chart"
echo "   - Sync automatically"
echo ""
echo "=========================================="
