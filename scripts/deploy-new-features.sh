#!/bin/bash
set -e

# ============================================
# Automated Backstage Deployment Script
# Use this script every time you add new features
# ============================================

echo "🚀 Backstage Automated Deployment"
echo "===================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKSTAGE_DIR="/Users/jaime.henao/arheanja/Backstage-solutions/backstage-kind-migration/backstage-kind"
DOCKER_IMAGE="jaimehenao8126/backstage-production"
K8S_NAMESPACE="backstage"

# Generate version tag based on timestamp
VERSION=$(date +%Y%m%d-%H%M%S)
IMAGE_TAG="${DOCKER_IMAGE}:${VERSION}"

echo -e "${BLUE}📦 Version: ${VERSION}${NC}"
echo -e "${BLUE}📁 Working directory: ${BACKSTAGE_DIR}${NC}"
echo ""

# Step 1: TypeScript Check
echo -e "${YELLOW}🔍 Step 1: Checking TypeScript compilation...${NC}"
cd "$BACKSTAGE_DIR"
yarn tsc --noEmit

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ TypeScript check passed!${NC}"
else
    echo -e "${RED}❌ TypeScript errors found! Please fix them first.${NC}"
    exit 1
fi
echo ""

# Step 2: Build Backend
echo -e "${YELLOW}🔨 Step 2: Building Backstage backend...${NC}"
yarn build:backend

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Backend build successful!${NC}"
else
    echo -e "${RED}❌ Backend build failed!${NC}"
    exit 1
fi
echo ""

# Step 3: Create Dockerfile if doesn't exist
if [ ! -f "Dockerfile.final" ]; then
    echo -e "${YELLOW}📝 Creating Dockerfile...${NC}"
    cat > Dockerfile.final <<'DOCKERFILE'
FROM node:20-bullseye-slim

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        netcat \
        python3 \
        build-essential \
        && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy skeleton and extract
COPY packages/backend/dist/skeleton.tar.gz ./
RUN tar xzf skeleton.tar.gz && rm skeleton.tar.gz

# Install production dependencies
RUN yarn install --frozen-lockfile --production --network-timeout 300000 && \
    rm -rf "$(yarn cache dir)"

# Copy bundle and extract
COPY packages/backend/dist/bundle.tar.gz ./
RUN tar xzf bundle.tar.gz && rm bundle.tar.gz

# Copy app-config files
COPY app-config.yaml app-config.production.yaml ./

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:7007/healthcheck || exit 1

EXPOSE 7007

ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=1024"

RUN chown -R 1000:1000 /app
USER 1000

CMD ["node", "packages/backend", "--config", "app-config.yaml", "--config", "app-config.production.yaml"]
DOCKERFILE
    echo -e "${GREEN}✅ Dockerfile created!${NC}"
fi
echo ""

# Step 4: Build Docker Image
echo -e "${YELLOW}🐳 Step 3: Building Docker image...${NC}"
docker build -t backstage:latest -f Dockerfile.final .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Docker image built successfully!${NC}"
else
    echo -e "${RED}❌ Docker build failed!${NC}"
    exit 1
fi
echo ""

# Step 5: Tag Images (both with version and latest)
echo -e "${YELLOW}🏷️  Step 4: Tagging Docker images...${NC}"
docker tag backstage:latest "${IMAGE_TAG}"
docker tag backstage:latest "${DOCKER_IMAGE}:latest"
echo -e "${GREEN}✅ Images tagged:${NC}"
echo -e "   - ${IMAGE_TAG}"
echo -e "   - ${DOCKER_IMAGE}:latest"
echo ""

# Step 6: Push to Registry
echo -e "${YELLOW}📤 Step 5: Pushing to Docker registry...${NC}"
docker push "${IMAGE_TAG}"
docker push "${DOCKER_IMAGE}:latest"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Images pushed successfully!${NC}"
else
    echo -e "${RED}❌ Docker push failed!${NC}"
    exit 1
fi
echo ""

# Step 7: Update Kubernetes Deployment
echo -e "${YELLOW}☸️  Step 6: Updating Kubernetes deployment...${NC}"
kubectl set image deployment/backstage backstage="${IMAGE_TAG}" -n "$K8S_NAMESPACE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Deployment updated with version: ${VERSION}${NC}"
else
    echo -e "${RED}❌ Kubernetes update failed!${NC}"
    exit 1
fi
echo ""

# Step 8: Rollout and Wait
echo -e "${YELLOW}🔄 Step 7: Rolling out new deployment...${NC}"
kubectl rollout status deployment/backstage -n "$K8S_NAMESPACE" --timeout=5m

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Rollout completed successfully!${NC}"
else
    echo -e "${RED}❌ Rollout failed or timed out!${NC}"
    echo -e "${YELLOW}Checking pod status...${NC}"
    kubectl get pods -n "$K8S_NAMESPACE" -l app=backstage
    echo ""
    echo -e "${YELLOW}Recent logs:${NC}"
    kubectl logs -n "$K8S_NAMESPACE" -l app=backstage --tail=20
    echo ""
    echo -e "${YELLOW}Recent events:${NC}"
    kubectl get events -n "$K8S_NAMESPACE" --sort-by='.lastTimestamp' | tail -10
    exit 1
fi
echo ""

# Step 9: Verification
echo -e "${YELLOW}🔍 Step 8: Verification...${NC}"
echo ""
echo -e "${BLUE}Pod Status:${NC}"
kubectl get pods -n "$K8S_NAMESPACE" -l app=backstage
echo ""
echo -e "${BLUE}Service Info:${NC}"
kubectl get svc -n "$K8S_NAMESPACE" -l app=backstage
echo ""
echo -e "${BLUE}Recent Logs:${NC}"
kubectl logs -n "$K8S_NAMESPACE" -l app=backstage --tail=10
echo ""

# Step 10: Success Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✨ Deployment Completed Successfully! ✨${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}📊 Deployment Details:${NC}"
echo -e "   Version: ${GREEN}${VERSION}${NC}"
echo -e "   Image: ${GREEN}${IMAGE_TAG}${NC}"
echo -e "   Namespace: ${GREEN}${K8S_NAMESPACE}${NC}"
echo ""
echo -e "${BLUE}🌐 Access URLs:${NC}"
echo -e "   Main: ${GREEN}http://backstage.kind.local${NC}"
echo -e "   Kubernetes: ${GREEN}http://backstage.kind.local/kubernetes${NC}"
echo -e "   Monitoring: ${GREEN}http://backstage.kind.local/monitoring${NC}"
echo -e "   GitOps: ${GREEN}http://backstage.kind.local/gitops${NC}"
echo -e "   GitHub: ${GREEN}http://backstage.kind.local/github${NC}"
echo ""
echo -e "${BLUE}🔧 Useful Commands:${NC}"
echo -e "   Monitor logs: ${GREEN}kubectl logs -f deployment/backstage -n backstage${NC}"
echo -e "   Check pods: ${GREEN}kubectl get pods -n backstage${NC}"
echo -e "   Restart: ${GREEN}kubectl rollout restart deployment/backstage -n backstage${NC}"
echo ""
echo -e "${BLUE}📝 Version History:${NC}"
echo -e "   Current: ${GREEN}${VERSION}${NC}"
echo -e "   Previous versions: ${YELLOW}docker images ${DOCKER_IMAGE}${NC}"
echo ""
