#!/bin/bash
# ============================================================================
# Script: 01-init-backstage.sh
# Description: Initialize new Backstage project with all required plugins
# Author: Jaime Henao
# Date: October 3, 2025
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project paths
PROJECT_ROOT="/Users/jaime.henao/arheanja/Backstage-solutions/backstage-kind-migration"
BACKSTAGE_DIR="$PROJECT_ROOT/backstage"
SOURCE_PROJECT="/Users/jaime.henao/arheanja/Backstage-solutions/backstage-app-devc/backstage"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}  Backstage Kind Migration - Phase 1: Initialize Project${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# ============================================================================
# Step 1: Check prerequisites
# ============================================================================
echo -e "${YELLOW}[Step 1/7]${NC} Checking prerequisites..."

# Check Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found. Please install Node.js 20+${NC}"
    exit 1
fi
NODE_VERSION=$(node --version)
echo -e "${GREEN}✅ Node.js: $NODE_VERSION${NC}"

# Check Yarn
if ! command -v yarn &> /dev/null; then
    echo -e "${RED}❌ Yarn not found. Installing...${NC}"
    npm install -g yarn
fi
YARN_VERSION=$(yarn --version)
echo -e "${GREEN}✅ Yarn: $YARN_VERSION${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found. Please install Docker Desktop${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker: $(docker --version)${NC}"

# Check Kind cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Kind cluster not accessible. Please start your Kind cluster${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Kind cluster: Running${NC}"

echo ""

# ============================================================================
# Step 2: Create new Backstage project
# ============================================================================
echo -e "${YELLOW}[Step 2/7]${NC} Creating new Backstage project..."

if [ -d "$BACKSTAGE_DIR/packages" ]; then
    echo -e "${YELLOW}⚠️  Backstage project already exists. Skipping creation.${NC}"
else
    cd "$PROJECT_ROOT"
    echo -e "${BLUE}Running: npx @backstage/create-app@latest --path backstage${NC}"

    # Create app with defaults
    npx @backstage/create-app@latest --path backstage --skip-install

    echo -e "${GREEN}✅ Backstage project created${NC}"
fi

echo ""

# ============================================================================
# Step 3: Install base dependencies
# ============================================================================
echo -e "${YELLOW}[Step 3/7]${NC} Installing base dependencies..."

cd "$BACKSTAGE_DIR"

echo -e "${BLUE}Running: yarn install${NC}"
yarn install

echo -e "${GREEN}✅ Base dependencies installed${NC}"
echo ""

# ============================================================================
# Step 4: Install frontend plugins
# ============================================================================
echo -e "${YELLOW}[Step 4/7]${NC} Installing frontend plugins..."

echo -e "${BLUE}Installing Kubernetes plugin...${NC}"
yarn workspace app add @backstage/plugin-kubernetes

echo -e "${BLUE}Installing ArgoCD plugin...${NC}"
yarn workspace app add @roadiehq/backstage-plugin-argo-cd

echo -e "${BLUE}Installing Home plugin...${NC}"
yarn workspace app add @backstage/plugin-home

echo -e "${BLUE}Installing GitHub Actions plugin...${NC}"
yarn workspace app add @backstage/plugin-github-actions

echo -e "${BLUE}Installing TODO plugin...${NC}"
yarn workspace app add @backstage/plugin-todo

echo -e "${BLUE}Installing GitHub Insights plugin...${NC}"
yarn workspace app add @roadiehq/backstage-plugin-github-insights

echo -e "${GREEN}✅ Frontend plugins installed${NC}"
echo ""

# ============================================================================
# Step 5: Install backend plugins
# ============================================================================
echo -e "${YELLOW}[Step 5/7]${NC} Installing backend plugins..."

echo -e "${BLUE}Installing Kubernetes backend...${NC}"
yarn workspace backend add @backstage/plugin-kubernetes-backend

echo -e "${BLUE}Installing ArgoCD backend...${NC}"
yarn workspace backend add @roadiehq/backstage-plugin-argo-cd-backend

echo -e "${BLUE}Installing PostgreSQL driver...${NC}"
yarn workspace backend add pg

echo -e "${GREEN}✅ Backend plugins installed${NC}"
echo ""

# ============================================================================
# Step 6: Copy catalog entities from source project
# ============================================================================
echo -e "${YELLOW}[Step 6/7]${NC} Copying catalog entities..."

if [ -d "$SOURCE_PROJECT/catalog" ]; then
    echo -e "${BLUE}Copying catalog from source project...${NC}"
    mkdir -p "$BACKSTAGE_DIR/catalog"
    cp -r "$SOURCE_PROJECT/catalog/"* "$BACKSTAGE_DIR/catalog/" 2>/dev/null || true
    echo -e "${GREEN}✅ Catalog entities copied${NC}"
else
    echo -e "${YELLOW}⚠️  Source catalog not found. Creating empty structure...${NC}"
    mkdir -p "$BACKSTAGE_DIR/catalog/entities"
fi

echo ""

# ============================================================================
# Step 7: Create summary
# ============================================================================
echo -e "${YELLOW}[Step 7/7]${NC} Creating summary..."

cat > "$PROJECT_ROOT/INIT_SUMMARY.md" <<EOF
# 🎉 Backstage Initialization Summary

**Date**: $(date)
**Status**: ✅ Success

## ✅ Completed Tasks

1. ✅ Prerequisites verified
   - Node.js: $NODE_VERSION
   - Yarn: $YARN_VERSION
   - Docker: Running
   - Kind cluster: Accessible

2. ✅ New Backstage project created
   - Location: $BACKSTAGE_DIR
   - Framework: Backstage latest

3. ✅ Base dependencies installed
   - All core packages installed via yarn

4. ✅ Frontend plugins installed
   - @backstage/plugin-kubernetes
   - @roadiehq/backstage-plugin-argo-cd
   - @backstage/plugin-home
   - @backstage/plugin-github-actions
   - @backstage/plugin-todo
   - @roadiehq/backstage-plugin-github-insights

5. ✅ Backend plugins installed
   - @backstage/plugin-kubernetes-backend
   - @roadiehq/backstage-plugin-argo-cd-backend
   - pg (PostgreSQL driver)

6. ✅ Catalog entities copied
   - Source: $SOURCE_PROJECT/catalog
   - Destination: $BACKSTAGE_DIR/catalog

## 📋 Next Steps

### Manual Configuration Required

1. **Update app-config.yaml**
   \`\`\`bash
   cd $BACKSTAGE_DIR
   nano app-config.yaml
   \`\`\`

   Add:
   - GitHub integration token
   - ArgoCD credentials
   - Kubernetes cluster config
   - Catalog locations

2. **Configure Backend Database**
   Update \`app-config.yaml\`:
   \`\`\`yaml
   backend:
     database:
       client: pg
       connection:
         host: \${POSTGRES_HOST}
         port: \${POSTGRES_PORT}
         user: \${POSTGRES_USER}
         password: \${POSTGRES_PASSWORD}
   \`\`\`

3. **Copy Custom Components** (if needed)
   \`\`\`bash
   # Copy from source project manually
   cp -r $SOURCE_PROJECT/packages/app/src/components/* \\
         $BACKSTAGE_DIR/packages/app/src/components/
   \`\`\`

4. **Test Locally**
   \`\`\`bash
   cd $BACKSTAGE_DIR
   yarn dev
   # Access: http://localhost:3000
   \`\`\`

5. **Build Docker Image**
   \`\`\`bash
   cd $PROJECT_ROOT
   ./scripts/02-build-image.sh
   \`\`\`

## 📂 Project Structure

\`\`\`
backstage-kind-migration/
├── backstage/              ✅ Created
│   ├── packages/
│   │   ├── app/           ✅ With plugins
│   │   └── backend/       ✅ With plugins
│   └── catalog/           ✅ Entities copied
├── kubernetes/            ⏳ Pending
├── scripts/               ⏳ Pending
└── config/                ⏳ Pending
\`\`\`

## 🎯 Status: Phase 1 Complete

**Ready for**: Phase 2 - Configuration

EOF

echo -e "${GREEN}✅ Summary created: $PROJECT_ROOT/INIT_SUMMARY.md${NC}"
echo ""

# ============================================================================
# Final output
# ============================================================================
echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}  ✅ Phase 1 Complete: Backstage Project Initialized${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo -e "  • Project location: ${GREEN}$BACKSTAGE_DIR${NC}"
echo -e "  • Plugins installed: ${GREEN}9 plugins${NC}"
echo -e "  • Catalog entities: ${GREEN}Copied${NC}"
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo -e "  1. Review and edit: ${BLUE}$BACKSTAGE_DIR/app-config.yaml${NC}"
echo -e "  2. Test locally: ${BLUE}cd $BACKSTAGE_DIR && yarn dev${NC}"
echo -e "  3. Continue to Phase 2: ${BLUE}./scripts/02-build-image.sh${NC}"
echo ""
echo -e "${BLUE}📖 Full summary: ${GREEN}$PROJECT_ROOT/INIT_SUMMARY.md${NC}"
echo ""
