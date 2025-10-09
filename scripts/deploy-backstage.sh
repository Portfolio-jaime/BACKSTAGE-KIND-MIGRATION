#!/bin/bash
set -e

echo "🚀 Backstage Deployment Script"
echo "==============================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
BACKSTAGE_DIR="/Users/jaime.henao/arheanja/Backstage-solutions/backstage-kind-migration/backstage-kind"
DOCKER_IMAGE="jaimehenao8126/backstage-production:latest"
K8S_NAMESPACE="backstage"

echo -e "${YELLOW}📁 Working directory: ${BACKSTAGE_DIR}${NC}"
echo ""

# Step 1: Build Backend
echo -e "${YELLOW}🔨 Step 1: Building Backstage backend...${NC}"
cd "$BACKSTAGE_DIR"
yarn build:backend

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Backend build successful!${NC}"
else
    echo -e "${RED}❌ Backend build failed!${NC}"
    exit 1
fi
echo ""

# Step 2: Build Docker Image
echo -e "${YELLOW}🐳 Step 2: Building Docker image...${NC}"
docker build -t backstage:latest -f Dockerfile.production .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Docker image built successfully!${NC}"
else
    echo -e "${RED}❌ Docker build failed!${NC}"
    exit 1
fi
echo ""

# Step 3: Tag Image
echo -e "${YELLOW}🏷️  Step 3: Tagging Docker image...${NC}"
docker tag backstage:latest "$DOCKER_IMAGE"
echo -e "${GREEN}✅ Image tagged as: ${DOCKER_IMAGE}${NC}"
echo ""

# Step 4: Push to Registry
echo -e "${YELLOW}📤 Step 4: Pushing to Docker registry...${NC}"
docker push "$DOCKER_IMAGE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Image pushed successfully!${NC}"
else
    echo -e "${RED}❌ Docker push failed!${NC}"
    exit 1
fi
echo ""

# Step 5: Update Kubernetes Deployment
echo -e "${YELLOW}☸️  Step 5: Updating Kubernetes deployment...${NC}"
kubectl set image deployment/backstage backstage="$DOCKER_IMAGE" -n "$K8S_NAMESPACE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Deployment updated!${NC}"
else
    echo -e "${RED}❌ Kubernetes update failed!${NC}"
    exit 1
fi
echo ""

# Step 6: Wait for Rollout
echo -e "${YELLOW}⏳ Step 6: Waiting for rollout to complete...${NC}"
kubectl rollout status deployment/backstage -n "$K8S_NAMESPACE" --timeout=5m

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Rollout completed successfully!${NC}"
else
    echo -e "${RED}❌ Rollout failed or timed out!${NC}"
    exit 1
fi
echo ""

# Step 7: Show Pod Status
echo -e "${YELLOW}📊 Step 7: Current pod status:${NC}"
kubectl get pods -n "$K8S_NAMESPACE" -l app=backstage
echo ""

# Step 8: Show Service Info
echo -e "${YELLOW}🌐 Step 8: Service information:${NC}"
kubectl get svc -n "$K8S_NAMESPACE" -l app=backstage
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✨ Deployment completed successfully! ✨${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo -e "   1. Access Backstage: ${GREEN}http://backstage.kind.local${NC}"
echo -e "   2. Check logs: ${GREEN}kubectl logs -f deployment/backstage -n backstage${NC}"
echo -e "   3. View custom pages in the sidebar!"
echo ""
