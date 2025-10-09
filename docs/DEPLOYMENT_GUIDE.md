# 🚀 Backstage on Kind - Complete Deployment Guide

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com/)
[![Backstage](https://img.shields.io/badge/Backstage-9BF0E1?style=for-the-badge&logo=backstage&logoColor=black)](https://backstage.io/)
[![Helm](https://img.shields.io/badge/Helm-0F1689?style=for-the-badge&logo=helm&logoColor=white)](https://helm.sh/)

## 📋 Table of Contents

1. [Architecture Overview](#-architecture-overview)
2. [Project Structure](#-project-structure)
3. [Prerequisites](#-prerequisites)
4. [Build Process](#-build-process)
5. [Deployment Methods](#-deployment-methods)
6. [Configuration](#-configuration)
7. [Monitoring & Operations](#-monitoring--operations)
8. [Troubleshooting](#-troubleshooting)

---

## 🏛️ Architecture Overview

### High-Level System Diagram

```
┌───────────────────────────────────────────────────────────────────────┐
│                          🌐 External Access                            │
│                      https://backstage.arhean.com                      │
└───────────────────────────────┬───────────────────────────────────────┘
                                │
                                ▼
                    ┌───────────────────────┐
                    │   🔒 Ingress (TLS)    │
                    │   Let's Encrypt Cert  │
                    │   nginx-ingress       │
                    └───────────┬───────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────────────┐
│                       ☸️  Kind Cluster (Local)                         │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────┐   │
│  │              📦 Namespace: backstage                           │   │
│  │                                                                 │   │
│  │  ┌────────────────────────────────────────────────────────┐   │   │
│  │  │         🔵 Service: backstage (ClusterIP)              │   │   │
│  │  │         Port: 80 → 7007                                │   │   │
│  │  │         Session Affinity: ClientIP (3h)                │   │   │
│  │  └──────────────────────┬─────────────────────────────────┘   │   │
│  │                         │                                      │   │
│  │                         ▼                                      │   │
│  │  ┌────────────────────────────────────────────────────────┐   │   │
│  │  │    📊 Deployment: backstage                            │   │   │
│  │  │    Replicas: 1                                         │   │   │
│  │  │    Strategy: RollingUpdate                             │   │   │
│  │  │                                                         │   │   │
│  │  │    ┌──────────────────────────────────────────────┐   │   │   │
│  │  │    │  🔧 Init Container: wait-for-postgres        │   │   │   │
│  │  │    │  Image: busybox:1.36                         │   │   │   │
│  │  │    │  Check: nc -z postgres:5432                  │   │   │   │
│  │  │    └──────────────────────────────────────────────┘   │   │   │
│  │  │                                                         │   │   │
│  │  │    ┌──────────────────────────────────────────────┐   │   │   │
│  │  │    │  🎭 Main Container: backstage                │   │   │   │
│  │  │    │                                              │   │   │   │
│  │  │    │  Image: jaimehenao8126/backstage-           │   │   │   │
│  │  │    │         production:v7                        │   │   │   │
│  │  │    │  Port: 7007                                  │   │   │   │
│  │  │    │  Runtime: Node.js 20                         │   │   │   │
│  │  │    │                                              │   │   │   │
│  │  │    │  Resources:                                  │   │   │   │
│  │  │    │    CPU: 250m → 1000m                         │   │   │   │
│  │  │    │    Memory: 512Mi → 2Gi                       │   │   │   │
│  │  │    │                                              │   │   │   │
│  │  │    │  Health Checks:                              │   │   │   │
│  │  │    │    ✅ Startup  (30s, max 2min)              │   │   │   │
│  │  │    │    ✅ Liveness (90s)                         │   │   │   │
│  │  │    │    ✅ Readiness (60s)                        │   │   │   │
│  │  │    │                                              │   │   │   │
│  │  │    │  Volumes:                                    │   │   │   │
│  │  │    │    📁 /tmp (1Gi)                             │   │   │   │
│  │  │    │    📁 /app/tmp (1Gi)                         │   │   │   │
│  │  │    └──────────────────────────────────────────────┘   │   │   │
│  │  │                                                         │   │   │
│  │  │    Security:                                            │   │   │
│  │  │    🔒 runAsNonRoot: true                                │   │   │
│  │  │    🔒 runAsUser: 1000                                   │   │   │
│  │  │    🔒 capabilities: drop ALL                            │   │   │
│  │  └────────────────────────────────────────────────────────┘   │   │
│  │                                                                 │   │
│  │  ┌────────────────────────────────────────────────────────┐   │   │
│  │  │    🗄️  StatefulSet: psql-postgresql                    │   │   │
│  │  │    Replicas: 1                                         │   │   │
│  │  │                                                         │   │   │
│  │  │    ┌──────────────────────────────────────────────┐   │   │   │
│  │  │    │  PostgreSQL 14                               │   │   │   │
│  │  │    │  Port: 5432                                  │   │   │   │
│  │  │    │  Database: backstage_plugin_catalog          │   │   │   │
│  │  │    │                                              │   │   │   │
│  │  │    │  💾 PersistentVolume: 8Gi                    │   │   │   │
│  │  │    │  📊 Metrics: Enabled                         │   │   │   │
│  │  │    └──────────────────────────────────────────────┘   │   │   │
│  │  └────────────────────────────────────────────────────────┘   │   │
│  │                                                                 │   │
│  │  ┌────────────────────────────────────────────────────────┐   │   │
│  │  │    🔐 Configuration                                     │   │   │
│  │  │                                                         │   │   │
│  │  │    ConfigMap: backstage-env-config                     │   │   │
│  │  │    - NODE_ENV=production                               │   │   │
│  │  │    - POSTGRES_HOST=psql-postgresql                     │   │   │
│  │  │    - POSTGRES_PORT=5432                                │   │   │
│  │  │                                                         │   │   │
│  │  │    Secret: backstage-secrets                           │   │   │
│  │  │    - POSTGRES_USER                                     │   │   │
│  │  │    - POSTGRES_PASSWORD                                 │   │   │
│  │  │    - GITHUB_TOKEN                                      │   │   │
│  │  └────────────────────────────────────────────────────────┘   │   │
│  │                                                                 │   │
│  │  ┌────────────────────────────────────────────────────────┐   │   │
│  │  │    🔑 RBAC                                              │   │   │
│  │  │                                                         │   │   │
│  │  │    ServiceAccount: backstage                           │   │   │
│  │  │    ClusterRole: backstage-backend                      │   │   │
│  │  │      - apiGroups: ["*"]                                │   │   │
│  │  │      - resources: ["*"]                                │   │   │
│  │  │      - verbs: ["get", "list", "watch"]                 │   │   │
│  │  └────────────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────────────┘
```

### Data Flow Diagram

```
┌─────────────┐
│   👤 User    │
└──────┬──────┘
       │
       │ HTTPS (443)
       ▼
┌─────────────────┐
│  Ingress (TLS)  │
│  Certificate:   │
│  Let's Encrypt  │
└────────┬────────┘
         │
         │ HTTP (80)
         ▼
┌─────────────────┐
│  Service (LB)   │
│  Type: ClusterIP│
│  SessionAffinity│
└────────┬────────┘
         │
         │ HTTP (7007)
         ▼
┌─────────────────────────────────────┐
│      Backstage Pod                  │
│                                     │
│  ┌────────────────────────────┐    │
│  │  React Frontend (Bundle)   │    │
│  │  • Static files             │    │
│  │  • Service workers          │    │
│  │  • App configuration        │    │
│  └────────────┬───────────────┘    │
│               │                     │
│               │ API Calls           │
│               ▼                     │
│  ┌────────────────────────────┐    │
│  │  Node.js Backend           │    │
│  │  • REST API                 │    │
│  │  • Plugin system            │    │
│  │  • Authentication           │    │
│  └────────────┬───────────────┘    │
│               │                     │
└───────────────┼─────────────────────┘
                │
                │ PostgreSQL Protocol (5432)
                ▼
┌─────────────────────────────────────┐
│      PostgreSQL StatefulSet         │
│                                     │
│  • Catalog database                 │
│  • User management                  │
│  • Plugin data                      │
│  • Persistent storage (8Gi)         │
└─────────────────────────────────────┘
```

### Docker Build Pipeline

```
┌────────────────────────────────────────────────────────────────┐
│                    🔨 Build Pipeline                            │
└────────────────────────────────────────────────────────────────┘

Step 1️⃣: Local Build (Development Machine)
┌──────────────────────────────────────────────────────────────┐
│  📦 Install Dependencies                                      │
│  $ cd backstage-kind                                         │
│  $ export TMPDIR=/tmp                                        │
│  $ yarn install                                              │
│  ✓ 1753 packages installed (370MB)                           │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│  🏗️  Build Backend                                            │
│  $ yarn workspace backend build                              │
│                                                              │
│  Output:                                                     │
│  • packages/backend/dist/bundle.tar.gz    (11MB)            │
│    └── Compiled TypeScript → JavaScript                     │
│    └── All backend code bundled                             │
│                                                              │
│  • packages/backend/dist/skeleton.tar.gz  (903B)            │
│    └── package.json structure                               │
│    └── Dependency manifest                                  │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│  🎨 Build Frontend                                            │
│  $ yarn workspace app build                                  │
│                                                              │
│  Output:                                                     │
│  • packages/app/dist/                                        │
│    ├── static/  (React bundles, ~5MB)                        │
│    ├── index.html                                            │
│    └── assets/ (icons, fonts)                                │
└──────────────────────────────────────────────────────────────┘
                            ↓
Step 2️⃣: Docker Image Build
┌──────────────────────────────────────────────────────────────┐
│  🐳 Dockerfile.kind                                           │
│                                                              │
│  FROM node:20-bullseye-slim                                  │
│  ├── Base image: ~150MB                                      │
│  └── Debian 11 (bullseye)                                    │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│  Layer 1: System Dependencies                                │
│  RUN apt-get install python3 g++ make                        │
│  Size: +200MB                                                │
│  Purpose: Build native Node.js modules                       │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│  Layer 2: Application Structure                              │
│  COPY skeleton.tar.gz → Extract                              │
│  Size: +1KB                                                  │
│  Purpose: package.json files structure                       │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│  Layer 3: Dependency Installation                            │
│  COPY yarn files                                             │
│  RUN yarn workspaces focus --all --production                │
│  Size: +400MB                                                │
│  Duration: ~4-5 minutes                                      │
│  Purpose: Install production dependencies only               │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│  Layer 4: Application Code                                   │
│  COPY bundle.tar.gz → Extract                                │
│  Size: +50MB                                                 │
│  Purpose: Compiled backend code                              │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│  Layer 5: Configuration                                      │
│  COPY app-config*.yaml                                       │
│  Size: +5KB                                                  │
│  Purpose: Runtime configuration                              │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│  Final Image: jaimehenao8126/backstage-production:v7         │
│  Total Size: ~800MB                                          │
│  Layers: 15                                                  │
│  Architecture: linux/arm64 (Apple Silicon)                   │
└──────────────────────────────────────────────────────────────┘
                            ↓
Step 3️⃣: Push to Registry
┌──────────────────────────────────────────────────────────────┐
│  ⬆️  Docker Push                                              │
│  $ docker push jaimehenao8126/backstage-production:v7        │
│  $ docker push jaimehenao8126/backstage-production:latest    │
│                                                              │
│  Registry: DockerHub (Public)                                │
│  Compression: gzip                                           │
│  Upload size: ~300MB (compressed)                            │
└──────────────────────────────────────────────────────────────┘
```

## 📂 Project Structure

```
backstage-kind-migration/
│
├── 📁 backstage-kind/              # Main application directory
│   │
│   ├── 📄 package.json             # Root workspace configuration
│   │   └── Workspaces: app, backend
│   │
│   ├── 📄 yarn.lock                # Dependency lock file (1753 packages)
│   ├── 📄 .yarnrc.yml              # Yarn 4 configuration
│   │   └── nodeLinker: node-modules
│   │
│   ├── 📁 .yarn/                   # Yarn 4 installation
│   │   ├── releases/
│   │   │   └── yarn-4.4.1.cjs
│   │   └── cache/                  # Package cache
│   │
│   ├── 📄 Dockerfile.kind          # Production Docker image
│   │   ├── Multi-stage build
│   │   ├── Production dependencies
│   │   └── Security hardening
│   │
│   ├── 📄 .dockerignore            # Docker build exclusions
│   │   ├── .git/
│   │   ├── .yarn/cache/
│   │   └── *.local.yaml
│   │
│   ├── 📄 app-config.yaml          # Base configuration
│   │   ├── App metadata
│   │   ├── Backend config
│   │   └── Plugin configuration
│   │
│   ├── 📄 app-config.production.yaml  # Production overrides
│   │   ├── Database connection
│   │   └── Auth providers
│   │
│   └── 📁 packages/
│       │
│       ├── 📁 app/                 # Frontend React application
│       │   ├── 📄 package.json
│       │   │   └── Dependencies: React 18, Material-UI
│       │   │
│       │   ├── 📁 src/
│       │   │   ├── App.tsx         # Main App component
│       │   │   ├── components/     # React components
│       │   │   └── plugins/        # Plugin integrations
│       │   │
│       │   └── 📁 dist/            # Build output
│       │       ├── static/         # JS/CSS bundles (~5MB)
│       │       ├── index.html
│       │       └── assets/
│       │
│       └── 📁 backend/              # Backend Node.js service
│           ├── 📄 package.json
│           │   └── Dependencies: Backstage plugins
│           │
│           ├── 📁 src/
│           │   ├── index.ts        # Entry point
│           │   └── plugins/        # Backend plugins
│           │
│           └── 📁 dist/            # Build output
│               ├── bundle.tar.gz   # Compiled code (11MB)
│               └── skeleton.tar.gz # Package structure (903B)
│
├── 📁 kubernetes/                  # Kubernetes manifests
│   │
│   ├── 📄 namespace.yaml          # Namespace: backstage
│   │   └── Labels, annotations
│   │
│   ├── 📄 deployment.yaml         # Main application deployment
│   │   ├── Replicas: 1
│   │   ├── Init containers
│   │   ├── Health probes
│   │   └── Resource limits
│   │
│   ├── 📄 service.yaml            # Service definition
│   │   ├── Type: ClusterIP
│   │   ├── Port: 80 → 7007
│   │   └── Session affinity: ClientIP
│   │
│   ├── 📄 ingress.yaml            # Ingress with TLS
│   │   ├── Host: backstage.arhean.com
│   │   ├── TLS: Let's Encrypt
│   │   └── Class: nginx
│   │
│   ├── 📄 configmap.yaml          # Environment variables
│   │   ├── NODE_ENV=production
│   │   ├── POSTGRES_HOST
│   │   └── Database settings
│   │
│   ├── 📄 secrets.yaml            # Sensitive data (base64)
│   │   ├── POSTGRES_USER
│   │   ├── POSTGRES_PASSWORD
│   │   └── GITHUB_TOKEN
│   │
│   └── 📄 rbac.yaml               # RBAC permissions
│       ├── ServiceAccount: backstage
│       ├── ClusterRole
│       └── ClusterRoleBinding
│
├── 📁 helm/                        # Helm chart
│   └── 📁 backstage/
│       ├── 📄 Chart.yaml           # Chart metadata
│       │   ├── Name: backstage
│       │   ├── Version: 1.0.0
│       │   └── AppVersion: 1.0.0
│       │
│       ├── 📄 values.yaml          # Default values
│       │   ├── Image configuration
│       │   ├── Resource limits
│       │   ├── Probes configuration
│       │   └── PostgreSQL settings
│       │
│       └── 📁 templates/
│           ├── 📄 _helpers.tpl     # Template functions
│           ├── 📄 deployment.yaml  # Parameterized deployment
│           └── 📄 service.yaml     # Parameterized service
│
├── 📁 docs/                        # Documentation
│   ├── 📄 DEPLOYMENT_GUIDE.md     # This file
│   ├── 📄 ARCHITECTURE.md         # Architecture details
│   └── 📄 TROUBLESHOOTING.md      # Common issues
│
├── 📄 Makefile                     # Automation commands
│   ├── Build targets
│   ├── Deploy targets
│   └── Operational targets
│
└── 📄 README.md                    # Project overview
```

### File Size Reference

| Directory/File | Size | Purpose |
|----------------|------|---------|
| `node_modules/` | ~1.08GB | All dependencies |
| `packages/backend/dist/bundle.tar.gz` | 11MB | Compiled backend |
| `packages/app/dist/` | ~5MB | Frontend static files |
| `.yarn/cache/` | 370MB | Yarn package cache |
| Docker image (uncompressed) | ~800MB | Production runtime |
| Docker image (compressed) | ~300MB | Registry storage |

## ✅ Prerequisites

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **RAM** | 8GB | 16GB+ |
| **CPU** | 2 cores | 4+ cores |
| **Disk** | 20GB free | 50GB+ free |
| **OS** | macOS 12+ | macOS 13+ |

### Required Software

#### 1. Docker Desktop
```bash
# Install
brew install --cask docker

# Verify
docker --version
# Expected: Docker version 24.0.0+

# Configure resources (Docker Desktop Settings)
Memory: 6GB minimum
CPU: 4 cores minimum
Disk: 60GB
```

#### 2. Kind (Kubernetes in Docker)
```bash
# Install
brew install kind

# Verify
kind --version
# Expected: kind v0.20.0+

# Create cluster (if not exists)
kind create cluster --name kind
```

#### 3. kubectl
```bash
# Install
brew install kubectl

# Verify
kubectl version --client
# Expected: v1.28.0+

# Test connection
kubectl cluster-info --context kind-kind
```

#### 4. Helm
```bash
# Install
brew install helm

# Verify
helm version
# Expected: v3.12.0+

# Add repositories (optional)
helm repo add stable https://charts.helm.sh/stable
helm repo update
```

#### 5. Node.js 20 LTS
```bash
# Install
brew install node@20

# Verify
node --version
# Expected: v20.x.x

# Configure PATH
echo 'export PATH="/usr/local/opt/node@20/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

#### 6. Yarn 4
```bash
# Enable Corepack
corepack enable

# Install Yarn 4
corepack prepare yarn@4.4.1 --activate

# Verify
yarn --version
# Expected: 4.4.1
```

### Environment Setup

```bash
# Set temp directory for macOS
export TMPDIR=/tmp
echo 'export TMPDIR=/tmp' >> ~/.zshrc

# Verify setup
echo $TMPDIR
# Expected: /tmp
```

## 🔨 Build Process

### Quick Build (Using Makefile)

```bash
# Navigate to project
cd /path/to/backstage-kind-migration

# Build everything
make build              # Build backend + frontend
make build-docker       # Create Docker image
make push-docker        # Push to DockerHub

# Or all in one
make prod-deploy        # Build, push, and deploy
```

### Manual Build Process

#### Step 1: Build Backend

```bash
cd backstage-kind
export TMPDIR=/tmp
yarn workspace backend build
```

**Output:**
```
╭─────────────────────────────────────────────────────╮
│                                                     │
│      Backstage Build                                │
│      Build backend                                  │
│                                                     │
╰─────────────────────────────────────────────────────╯

Building package backend
Compiling...
✓ Successfully compiled
Creating bundle and skeleton archive...
Output written to packages/backend/dist

Build succeeded!
Duration: 45.2s

Output files:
  • bundle.tar.gz    11,107,289 bytes
  • skeleton.tar.gz       903 bytes
```

**What happens:**
- TypeScript → JavaScript compilation
- Dependencies bundled
- Source maps generated
- Archives created for Docker

#### Step 2: Build Frontend

```bash
yarn workspace app build
```

**Output:**
```
╭─────────────────────────────────────────────────────╮
│                                                     │
│      Backstage Build                                │
│      Build app                                      │
│                                                     │
╰─────────────────────────────────────────────────────╯

Building package app
Compiling...
✓ Successfully compiled
Generating static bundle...
Output written to packages/app/dist

Build succeeded!
Duration: 62.8s

Output files:
  • static/             5,234,567 bytes
  • index.html              2,345 bytes
  • assets/               456,789 bytes
```

**What happens:**
- React components compiled
- Webpack bundling
- Code splitting
- Static assets optimized

#### Step 3: Build Docker Image

```bash
docker build -f backstage-kind/Dockerfile.kind \
  -t jaimehenao8126/backstage-production:v7 \
  backstage-kind/
```

**Build stages:**

```
[1/12] FROM node:20-bullseye-slim
└─ Using cached layer

[2/12] RUN apt-get update && apt-get install...
├─ Installing: python3, g++, make
└─ Size: +200MB, Duration: 28s

[3/12] WORKDIR /app
└─ Setting working directory

[4/12] COPY skeleton.tar.gz
└─ Size: +903B

[5/12] RUN tar xzf skeleton.tar.gz
└─ Extracting package structure

[6/12] COPY yarn files
└─ Size: +2MB

[7/12] RUN yarn workspaces focus --all --production
├─ Installing 1208 packages
├─ Building native modules
└─ Size: +400MB, Duration: 4m38s

[8/12] COPY bundle.tar.gz
└─ Size: +11MB

[9/12] RUN tar xzf bundle.tar.gz
└─ Extracting compiled code

[10/12] COPY app-config files
└─ Size: +5KB

[11/12] RUN chown -R 1000:1000 /app
└─ Setting ownership, Duration: 171s

[12/12] CMD ["node", "packages/backend"...]
└─ Setting entrypoint

Image built successfully!
Total time: ~8 minutes
Final size: 800MB
```

#### Step 4: Tag & Push

```bash
# Tag as latest
docker tag jaimehenao8126/backstage-production:v7 \
  jaimehenao8126/backstage-production:latest

# Push version tag
docker push jaimehenao8126/backstage-production:v7

# Push latest tag
docker push jaimehenao8126/backstage-production:latest
```

**Push output:**
```
The push refers to repository [docker.io/jaimehenao8126/backstage-production]
7e4120173ef0: Pushed
027604b1d149: Pushed
db5906dcc5a3: Pushed
...
v7: digest: sha256:c74b44952dfb... size: 3678
```

## 🚀 Deployment Methods

### Method 1: Makefile (Recommended)

```bash
# Full deployment
make deploy

# Or with Helm
make helm-install    # First time
make helm-upgrade    # Updates
```

### Method 2: kubectl (Manual)

```bash
# Apply in order
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/rbac.yaml
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/secrets.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/ingress.yaml

# Verify
kubectl get all -n backstage
```

### Method 3: Helm Chart

```bash
# Install
helm install backstage helm/backstage \
  -n backstage \
  --create-namespace \
  --set image.tag=v7 \
  --wait --timeout 10m

# Upgrade
helm upgrade backstage helm/backstage \
  -n backstage \
  --set image.tag=v8 \
  --wait

# Uninstall
helm uninstall backstage -n backstage
```

## 📊 Deployment Verification

### Step-by-Step Verification

#### 1. Check Pod Status
```bash
$ kubectl get pods -n backstage

NAME                         READY   STATUS    RESTARTS   AGE
backstage-76b7ff7c68-gtf48   1/1     Running   0          5m
psql-postgresql-0            1/1     Running   0          10m
```

**Expected states:**
- ✅ `Running` - Pod is healthy
- ⚠️ `Pending` - Waiting for resources
- ⚠️ `ContainerCreating` - Pulling image
- ❌ `CrashLoopBackOff` - Application error
- ❌ `Error` - Failed to start

#### 2. Check Logs
```bash
$ make logs
# or
$ kubectl logs -f -n backstage -l app=backstage

{"level":"info","message":"Listening on :7007","service":"rootHttpRouter"}
{"level":"info","message":"PostgreSQL connection established"}
{"level":"info","message":"Backstage started successfully"}
```

**Healthy log patterns:**
- ✅ `Listening on :7007`
- ✅ `PostgreSQL connection established`
- ✅ Healthcheck returns HTTP 200
- ❌ `ECONNREFUSED` - Can't connect to DB
- ❌ `MODULE_NOT_FOUND` - Missing dependencies

#### 3. Test Health Endpoint
```bash
$ make port-forward
# In another terminal:
$ curl http://localhost:7007/healthcheck

{
  "status": "ok",
  "checks": {
    "database": "healthy",
    "catalog": "healthy"
  }
}
```

#### 4. Verify Service
```bash
$ kubectl get svc -n backstage

NAME        TYPE        CLUSTER-IP      PORT(S)
backstage   ClusterIP   10.96.123.45    80/TCP
```

#### 5. Check Ingress
```bash
$ kubectl get ingress -n backstage

NAME        CLASS   HOSTS                    ADDRESS         PORTS
backstage   nginx   backstage.arhean.com    192.168.1.100   80,443
```

---

**Continue to Part 2: [Configuration & Operations →](./DEPLOYMENT_GUIDE_PART2.md)**
