#!/bin/bash
# ============================================================================
# Script: 03-deploy-to-kind.sh
# Description: Deploy Backstage to Kind cluster
# Author: Jaime Henao
# Date: October 3, 2025
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PROJECT_ROOT="/Users/jaime.henao/arheanja/Backstage-solutions/backstage-kind-migration"
K8S_DIR="$PROJECT_ROOT/kubernetes"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}  Backstage Kind Migration - Phase 3: Deploy to Kind${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# ============================================================================
# Step 1: Verify Kind cluster
# ============================================================================
echo -e "${YELLOW}[Step 1/8]${NC} Verifying Kind cluster..."

if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Kind cluster not accessible${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Kind cluster accessible${NC}"
echo ""

# ============================================================================
# Step 2: Create/Verify namespace
# ============================================================================
echo -e "${YELLOW}[Step 2/8]${NC} Creating namespace..."

kubectl apply -f "$K8S_DIR/namespace.yaml"

echo -e "${GREEN}✅ Namespace ready${NC}"
echo ""

# ============================================================================
# Step 3: Apply RBAC
# ============================================================================
echo -e "${YELLOW}[Step 3/8]${NC} Applying RBAC configuration..."

kubectl apply -f "$K8S_DIR/rbac.yaml"

echo -e "${GREEN}✅ RBAC configured${NC}"
echo ""

# ============================================================================
# Step 4: Apply Secrets
# ============================================================================
echo -e "${YELLOW}[Step 4/8]${NC} Applying secrets..."

# Check if secrets already exist
if kubectl get secret backstage-secrets -n backstage &> /dev/null; then
    echo -e "${YELLOW}⚠️  Secrets already exist. Updating...${NC}"
    kubectl apply -f "$K8S_DIR/secrets.yaml"
else
    kubectl apply -f "$K8S_DIR/secrets.yaml"
fi

echo -e "${GREEN}✅ Secrets configured${NC}"
echo ""

# ============================================================================
# Step 5: Apply ConfigMaps
# ============================================================================
echo -e "${YELLOW}[Step 5/8]${NC} Applying ConfigMaps..."

kubectl apply -f "$K8S_DIR/configmap.yaml"

echo -e "${GREEN}✅ ConfigMaps configured${NC}"
echo ""

# ============================================================================
# Step 6: Apply Service
# ============================================================================
echo -e "${YELLOW}[Step 6/8]${NC} Applying Service..."

kubectl apply -f "$K8S_DIR/service.yaml"

echo -e "${GREEN}✅ Service created${NC}"
echo ""

# ============================================================================
# Step 7: Apply Deployment
# ============================================================================
echo -e "${YELLOW}[Step 7/8]${NC} Applying Deployment..."

kubectl apply -f "$K8S_DIR/deployment.yaml"

echo -e "${BLUE}Waiting for deployment rollout...${NC}"
kubectl rollout status deployment/backstage -n backstage --timeout=5m

echo -e "${GREEN}✅ Deployment ready${NC}"
echo ""

# ============================================================================
# Step 8: Apply Ingress
# ============================================================================
echo -e "${YELLOW}[Step 8/8]${NC} Applying Ingress..."

kubectl apply -f "$K8S_DIR/ingress.yaml"

echo -e "${GREEN}✅ Ingress configured${NC}"
echo ""

# ============================================================================
# Final status
# ============================================================================
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}  ✅ Phase 3 Complete: Backstage Deployed to Kind${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo ""

echo -e "${BLUE}📊 Deployment Status:${NC}"
kubectl get pods,svc,ingress -n backstage
echo ""

echo -e "${BLUE}📝 Pod Logs (last 20 lines):${NC}"
kubectl logs -n backstage -l app=backstage --tail=20 --prefix
echo ""

echo -e "${YELLOW}📝 Next Steps:${NC}"
echo -e "  1. Check /etc/hosts has: ${BLUE}127.0.0.1 backstage.kind.local${NC}"
echo -e "  2. Access Backstage: ${GREEN}http://backstage.kind.local${NC}"
echo -e "  3. View logs: ${BLUE}kubectl logs -n backstage -l app=backstage -f${NC}"
echo -e "  4. Run validation: ${BLUE}./scripts/04-verify-deployment.sh${NC}"
echo ""
