#!/bin/bash
# ============================================================================
# Script: 02-build-image.sh
# Description: Build Docker image and load into Kind cluster
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
BACKSTAGE_DIR="$PROJECT_ROOT/backstage-kind"
IMAGE_NAME="backstage-kind"
IMAGE_TAG="latest"
IMAGE_FULL="${IMAGE_NAME}:${IMAGE_TAG}"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}  Backstage Kind Migration - Phase 2: Build Docker Image${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# ============================================================================
# Step 1: Verify Dockerfile exists
# ============================================================================
echo -e "${YELLOW}[Step 1/5]${NC} Verifying Dockerfile..."

if [ ! -f "$BACKSTAGE_DIR/Dockerfile.production" ]; then
    echo -e "${RED}❌ Dockerfile.production not found${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Dockerfile.production found${NC}"
echo ""

# ============================================================================
# Step 2: Build Docker image
# ============================================================================
echo -e "${YELLOW}[Step 2/5]${NC} Building Docker image..."
echo -e "${BLUE}Image: ${IMAGE_FULL}${NC}"
echo ""

cd "$PROJECT_ROOT"

docker build \
  -f "$BACKSTAGE_DIR/Dockerfile.production" \
  -t "${IMAGE_FULL}" \
  "$BACKSTAGE_DIR"

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Docker build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Image built successfully${NC}"
echo ""

# ============================================================================
# Step 3: Verify image exists
# ============================================================================
echo -e "${YELLOW}[Step 3/5]${NC} Verifying image..."

if ! docker images | grep -q "${IMAGE_NAME}"; then
    echo -e "${RED}❌ Image not found in Docker${NC}"
    exit 1
fi

IMAGE_SIZE=$(docker images "${IMAGE_FULL}" --format "{{.Size}}")
echo -e "${GREEN}✅ Image verified${NC}"
echo -e "   Size: ${BLUE}${IMAGE_SIZE}${NC}"
echo ""

# ============================================================================
# Step 4: Load image into Kind cluster
# ============================================================================
echo -e "${YELLOW}[Step 4/5]${NC} Loading image into Kind cluster..."

if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Kind cluster not accessible${NC}"
    exit 1
fi

kind load docker-image "${IMAGE_FULL}" --name kind

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to load image into Kind${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Image loaded into Kind${NC}"
echo ""

# ============================================================================
# Step 5: Verify image in Kind
# ============================================================================
echo -e "${YELLOW}[Step 5/5]${NC} Verifying image in Kind..."

docker exec kind-control-plane crictl images | grep backstage-kind || {
    echo -e "${RED}❌ Image not found in Kind cluster${NC}"
    exit 1
}

echo -e "${GREEN}✅ Image verified in Kind cluster${NC}"
echo ""

# ============================================================================
# Final output
# ============================================================================
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}  ✅ Phase 2 Complete: Docker Image Built and Loaded${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo ""
echo -e "${BLUE}📋 Image Details:${NC}"
echo -e "  • Name: ${GREEN}${IMAGE_FULL}${NC}"
echo -e "  • Size: ${GREEN}${IMAGE_SIZE}${NC}"
echo -e "  • Location: ${GREEN}Kind cluster${NC}"
echo ""
echo -e "${YELLOW}📝 Next Step:${NC}"
echo -e "  Deploy to Kind: ${BLUE}./scripts/03-deploy-to-kind.sh${NC}"
echo ""
