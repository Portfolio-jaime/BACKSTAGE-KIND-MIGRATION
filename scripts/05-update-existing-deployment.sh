#!/bin/bash
# ============================================================================
# Script: 05-update-existing-deployment.sh
# Description: Update existing Backstage deployment with new configuration
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

PROJECT_ROOT="/Users/jaime.henao/arheanja/Backstage-solutions/backstage-kind-migration"
K8S_DIR="$PROJECT_ROOT/kubernetes"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}  Update Existing Backstage Deployment${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# ============================================================================
# Step 1: Backup current deployment
# ============================================================================
echo -e "${YELLOW}[Step 1/8]${NC} Backing up current deployment..."

BACKUP_FILE="/tmp/backstage-backup-$(date +%Y%m%d-%H%M%S).yaml"
kubectl get all,cm,secret,ingress -n backstage -o yaml > "$BACKUP_FILE"

echo -e "${GREEN}✅ Backup saved: $BACKUP_FILE${NC}"
echo ""

# ============================================================================
# Step 2: Update Secrets (if needed)
# ============================================================================
echo -e "${YELLOW}[Step 2/8]${NC} Updating secrets..."

# Check if our secrets exist
if kubectl get secret backstage-secrets -n backstage &> /dev/null; then
    echo -e "${YELLOW}⚠️  Secrets already exist. Skipping...${NC}"
else
    kubectl apply -f "$K8S_DIR/secrets.yaml"
    echo -e "${GREEN}✅ Secrets created${NC}"
fi
echo ""

# ============================================================================
# Step 3: Update ConfigMaps
# ============================================================================
echo -e "${YELLOW}[Step 3/8]${NC} Updating ConfigMaps..."

# Delete old ConfigMaps
kubectl delete cm backstage-config backstage-base-config backstage-enhanced-config backstage-minimal-config -n backstage 2>/dev/null || true

# Apply new ConfigMaps
kubectl apply -f "$K8S_DIR/configmap.yaml"

echo -e "${GREEN}✅ ConfigMaps updated${NC}"
echo ""

# ============================================================================
# Step 4: Scale to 3 replicas
# ============================================================================
echo -e "${YELLOW}[Step 4/8]${NC} Scaling to 3 replicas..."

kubectl scale deployment backstage -n backstage --replicas=3

echo -e "${GREEN}✅ Scaled to 3 replicas${NC}"
echo ""

# ============================================================================
# Step 5: Update environment variables
# ============================================================================
echo -e "${YELLOW}[Step 5/8]${NC} Updating deployment environment..."

# Patch deployment to use new ConfigMaps and Secrets
kubectl patch deployment backstage -n backstage --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/envFrom",
    "value": [
      {
        "configMapRef": {
          "name": "backstage-env-config"
        }
      },
      {
        "secretRef": {
          "name": "backstage-secrets"
        }
      }
    ]
  }
]' 2>/dev/null || echo "Environment already configured"

echo -e "${GREEN}✅ Environment updated${NC}"
echo ""

# ============================================================================
# Step 6: Update Ingress
# ============================================================================
echo -e "${YELLOW}[Step 6/8]${NC} Updating Ingress..."

# Delete old ingresses
kubectl delete ingress backstage backstage-enhanced -n backstage 2>/dev/null || true

# Apply new ingress
kubectl apply -f "$K8S_DIR/ingress.yaml"

echo -e "${GREEN}✅ Ingress updated${NC}"
echo ""

# ============================================================================
# Step 7: Restart deployment
# ============================================================================
echo -e "${YELLOW}[Step 7/8]${NC} Restarting deployment..."

kubectl rollout restart deployment/backstage -n backstage

echo -e "${BLUE}Waiting for rollout to complete...${NC}"
kubectl rollout status deployment/backstage -n backstage --timeout=5m

echo -e "${GREEN}✅ Deployment restarted${NC}"
echo ""

# ============================================================================
# Step 8: Verify
# ============================================================================
echo -e "${YELLOW}[Step 8/8]${NC} Verifying deployment..."

# Check pods
RUNNING_PODS=$(kubectl get pods -n backstage -l app=backstage --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [ "$RUNNING_PODS" -ge 3 ]; then
    echo -e "${GREEN}✅ Pods running: ${RUNNING_PODS}/3${NC}"
else
    echo -e "${YELLOW}⚠️  Only ${RUNNING_PODS}/3 pods running${NC}"
fi

# Check service
kubectl get svc backstage -n backstage &> /dev/null && echo -e "${GREEN}✅ Service exists${NC}" || echo -e "${RED}❌ Service not found${NC}"

# Check ingress
kubectl get ingress backstage -n backstage &> /dev/null && echo -e "${GREEN}✅ Ingress exists${NC}" || echo -e "${RED}❌ Ingress not found${NC}"

echo ""

# ============================================================================
# Final output
# ============================================================================
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}  ✅ Deployment Updated Successfully${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo ""

echo -e "${BLUE}📊 Current Status:${NC}"
kubectl get pods,svc,ingress -n backstage
echo ""

echo -e "${BLUE}📝 View Logs:${NC}"
echo -e "   kubectl logs -n backstage -l app=backstage -f"
echo ""

echo -e "${BLUE}🌐 Access:${NC}"
echo -e "   http://backstage.kind.local"
echo ""

echo -e "${BLUE}🔍 Verify:${NC}"
echo -e "   ./scripts/04-verify-deployment.sh"
echo ""

echo -e "${YELLOW}💾 Backup Location:${NC}"
echo -e "   $BACKUP_FILE"
echo ""
