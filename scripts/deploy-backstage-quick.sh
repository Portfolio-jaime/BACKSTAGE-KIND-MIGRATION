#!/bin/bash
set -e

echo "🚀 Backstage Quick Deployment Script"
echo "======================================"
echo ""
echo "This script uses the pre-built backend from local machine"
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

# Check if dist-workspace exists
if [ ! -d "$BACKSTAGE_DIR/dist-workspace" ]; then
    echo -e "${YELLOW}🔨 Building backend (dist-workspace not found)...${NC}"
    cd "$BACKSTAGE_DIR"
    yarn build:backend

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Backend build failed!${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ Backend build successful!${NC}"
else
    echo -e "${GREEN}✅ Using existing dist-workspace${NC}"
fi
echo ""

# Step 2: Build Docker Image using simple Dockerfile
echo -e "${YELLOW}🐳 Building Docker image (quick method)...${NC}"
cd "$BACKSTAGE_DIR"

# Create a temporary simplified Dockerfile
cat > Dockerfile.deploy <<'EOF'
FROM node:20-bullseye-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        netcat \
        && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy pre-built workspace
COPY dist-workspace .

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:7007/healthcheck || exit 1

EXPOSE 7007

ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=1024"

RUN chown -R 1000:1000 /app
USER 1000

CMD ["node", "packages/backend", "--config", "app-config.yaml"]
EOF

docker build -t backstage:latest -f Dockerfile.deploy .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Docker image built successfully!${NC}"
    # Clean up temporary Dockerfile
    rm -f Dockerfile.deploy
else
    echo -e "${RED}❌ Docker build failed!${NC}"
    rm -f Dockerfile.deploy
    exit 1
fi
echo ""

# Step 3: Tag Image
echo -e "${YELLOW}🏷️  Tagging Docker image...${NC}"
docker tag backstage:latest "$DOCKER_IMAGE"
echo -e "${GREEN}✅ Image tagged as: ${DOCKER_IMAGE}${NC}"
echo ""

# Step 4: Push to Registry
echo -e "${YELLOW}📤 Pushing to Docker registry...${NC}"
docker push "$DOCKER_IMAGE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Image pushed successfully!${NC}"
else
    echo -e "${RED}❌ Docker push failed!${NC}"
    exit 1
fi
echo ""

# Step 5: Update Kubernetes Deployment
echo -e "${YELLOW}☸️  Updating Kubernetes deployment...${NC}"
kubectl set image deployment/backstage backstage="$DOCKER_IMAGE" -n "$K8S_NAMESPACE"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Deployment updated!${NC}"
else
    echo -e "${RED}❌ Kubernetes update failed!${NC}"
    exit 1
fi
echo ""

# Step 6: Restart deployment to force pull new image
echo -e "${YELLOW}🔄 Restarting deployment...${NC}"
kubectl rollout restart deployment/backstage -n "$K8S_NAMESPACE"
echo ""

# Step 7: Wait for Rollout
echo -e "${YELLOW}⏳ Waiting for rollout to complete...${NC}"
kubectl rollout status deployment/backstage -n "$K8S_NAMESPACE" --timeout=5m

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Rollout completed successfully!${NC}"
else
    echo -e "${RED}❌ Rollout failed or timed out!${NC}"
    echo -e "${YELLOW}Checking pod status...${NC}"
    kubectl get pods -n "$K8S_NAMESPACE" -l app=backstage
    echo ""
    echo -e "${YELLOW}Recent events:${NC}"
    kubectl get events -n "$K8S_NAMESPACE" --sort-by='.lastTimestamp' | tail -10
    exit 1
fi
echo ""

# Step 8: Show Pod Status
echo -e "${YELLOW}📊 Current pod status:${NC}"
kubectl get pods -n "$K8S_NAMESPACE" -l app=backstage
echo ""

# Step 9: Show Service Info
echo -e "${YELLOW}🌐 Service information:${NC}"
kubectl get svc -n "$K8S_NAMESPACE" -l app=backstage
echo ""

# Step 10: Show logs (last 20 lines)
echo -e "${YELLOW}📝 Recent logs:${NC}"
kubectl logs -n "$K8S_NAMESPACE" -l app=backstage --tail=20
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✨ Deployment completed successfully! ✨${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}📝 Access your Backstage:${NC}"
echo -e "   • Main: ${GREEN}http://backstage.kind.local${NC}"
echo -e "   • Kubernetes: ${GREEN}http://backstage.kind.local/kubernetes${NC}"
echo -e "   • Monitoring: ${GREEN}http://backstage.kind.local/monitoring${NC}"
echo -e "   • GitOps: ${GREEN}http://backstage.kind.local/gitops${NC}"
echo -e "   • GitHub: ${GREEN}http://backstage.kind.local/github${NC}"
echo ""
echo -e "${YELLOW}🔍 Monitor logs:${NC}"
echo -e "   ${GREEN}kubectl logs -f deployment/backstage -n backstage${NC}"
echo ""
