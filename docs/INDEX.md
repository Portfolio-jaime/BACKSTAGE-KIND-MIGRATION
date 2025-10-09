# 📚 Backstage on Kind - Documentation Index

Welcome to the complete documentation for the Backstage on Kubernetes (Kind) deployment project.

## 🎯 Quick Start

New to the project? Start here:

1. **[Quick Reference Guide](./QUICK_REFERENCE.md)** - Essential commands and troubleshooting
2. **[Deployment Guide](./DEPLOYMENT_GUIDE.md)** - Step-by-step deployment instructions
3. **[Main README](../README.md)** - Project overview

---

## 📋 Documentation Structure

### 🚀 Getting Started

| Document | Description | Audience |
|----------|-------------|----------|
| **[README.md](../README.md)** | Project overview and quick start | Everyone |
| **[Deployment Guide](./DEPLOYMENT_GUIDE.md)** | Complete deployment walkthrough | Operators, DevOps |
| **[Quick Reference](./QUICK_REFERENCE.md)** | Command cheat sheet and troubleshooting | Developers, Operators |

### 🏗️ Architecture & Design

| Document | Description | Audience |
|----------|-------------|----------|
| **[Architecture Diagrams](./ARCHITECTURE_DIAGRAMS.md)** | Complete system diagrams and data flows | Architects, Developers |

### 🔧 Operations

| Document | Description | Audience |
|----------|-------------|----------|
| **[Makefile](../Makefile)** | Automation commands | Operators |
| **[Helm Chart](../helm/backstage/)** | Helm chart configuration | DevOps |

### 📦 Configuration

| Document | Description | Audience |
|----------|-------------|----------|
| **[Kubernetes Manifests](../kubernetes/)** | K8s resource definitions | Operators |
| **[Values.yaml](../helm/backstage/values.yaml)** | Helm chart values | Operators |
| **[Dockerfile](../backstage-kind/Dockerfile.kind)** | Container image build | Developers |

---

## 🗂️ Documentation by Topic

### Build & Deployment

```
📘 Build Process
├─ Deployment Guide § Build Process
├─ Quick Reference § Build Commands
└─ Makefile (targets: build, build-docker, push-docker)

📘 Deployment Methods
├─ Deployment Guide § Deployment Methods
├─ Quick Reference § Deployment Commands
└─ Helm Chart Documentation
```

### Configuration

```
📗 Environment Configuration
├─ Quick Reference § Configuration Reference
├─ kubernetes/configmap.yaml
├─ kubernetes/secrets.yaml
└─ helm/backstage/values.yaml

📗 Resource Limits
├─ Quick Reference § Resource Specifications
├─ Deployment Guide § Resource Limits
└─ values.yaml (resources section)
```

### Architecture

```
📕 System Architecture
├─ Architecture Diagrams § Component Architecture
├─ Architecture Diagrams § Network Flow
└─ Deployment Guide § Architecture

📕 Data Flow
├─ Architecture Diagrams § Data Flow
└─ Architecture Diagrams § Plugin Data Flow
```

### Troubleshooting

```
📙 Problem Resolution
├─ Quick Reference § Troubleshooting Matrix
├─ Deployment Guide § Troubleshooting
└─ Quick Reference § Troubleshooting Workflows
```

### Operations

```
📓 Day-to-Day Operations
├─ Quick Reference § Command Reference
├─ Quick Reference § Operational Commands
└─ Makefile Reference
```

---

## 🎓 Learning Paths

### Path 1: Developer (New to Project)

```
Day 1: Understanding
├─ 1. Read: README.md
├─ 2. Scan: Architecture Diagrams
└─ 3. Try: make help

Day 2: Hands-On
├─ 1. Follow: Deployment Guide § Prerequisites
├─ 2. Run: make install-deps
├─ 3. Build: make build
└─ 4. Test: make dev

Day 3: Deployment
├─ 1. Read: Deployment Guide § Build Process
├─ 2. Build: make build-docker
├─ 3. Deploy: make deploy
└─ 4. Verify: make status
```

### Path 2: Operator (Managing Deployment)

```
Week 1: Foundation
├─ 1. Read: Deployment Guide (complete)
├─ 2. Study: Quick Reference § Command Reference
├─ 3. Practice: All make commands
└─ 4. Understand: Architecture Diagrams

Week 2: Advanced
├─ 1. Master: Helm Chart configuration
├─ 2. Learn: Kubernetes manifests
├─ 3. Practice: Troubleshooting workflows
└─ 4. Optimize: Resource limits
```

### Path 3: Architect (Designing System)

```
Phase 1: Analysis
├─ 1. Deep dive: Architecture Diagrams (all sections)
├─ 2. Review: Deployment Guide § Architecture
├─ 3. Analyze: Data flows
└─ 4. Understand: Security model

Phase 2: Planning
├─ 1. Review: Current specs
├─ 2. Plan: Scaling strategy
├─ 3. Design: High availability
└─ 4. Document: Architecture decisions
```

---

## 🔍 Quick Links by Use Case

### "I need to deploy Backstage"
→ [Deployment Guide](./DEPLOYMENT_GUIDE.md) § Quick Start

### "I have a build error"
→ [Quick Reference](./QUICK_REFERENCE.md) § Troubleshooting Matrix

### "I need to understand the architecture"
→ [Architecture Diagrams](./ARCHITECTURE_DIAGRAMS.md)

### "I want to customize the deployment"
→ [Helm Chart values.yaml](../helm/backstage/values.yaml)

### "I need to update environment variables"
→ [Quick Reference](./QUICK_REFERENCE.md) § Configuration Reference

### "Pod is crashing, what do I do?"
→ [Quick Reference](./QUICK_REFERENCE.md) § Troubleshooting Workflows

### "How do I scale the application?"
→ [values.yaml](../helm/backstage/values.yaml) → `replicaCount`

### "I want to update to a new version"
→ ```bash
make build
make push-docker
make helm-upgrade
```

---

## 📊 Component Reference Table

| Component | Location | Documentation | Purpose |
|-----------|----------|---------------|---------|
| **Backstage App** | `backstage-kind/packages/app/` | [Build Guide](./DEPLOYMENT_GUIDE.md) | Frontend React application |
| **Backend API** | `backstage-kind/packages/backend/` | [Build Guide](./DEPLOYMENT_GUIDE.md) | Node.js backend service |
| **Docker Image** | `Dockerfile.kind` | [Deployment Guide](./DEPLOYMENT_GUIDE.md) § Docker Build | Production container image |
| **Kubernetes** | `kubernetes/` | [Quick Reference](./QUICK_REFERENCE.md) | K8s resource manifests |
| **Helm Chart** | `helm/backstage/` | [values.yaml](../helm/backstage/values.yaml) | Helm deployment chart |
| **PostgreSQL** | StatefulSet | [Architecture](./ARCHITECTURE_DIAGRAMS.md) | Database for catalog |
| **Makefile** | Root | [Quick Reference](./QUICK_REFERENCE.md) § Commands | Automation tool |

---

## 🔧 Configuration Files Reference

### Essential Files

```
backstage-kind-migration/
│
├─ 📄 Makefile                          # Automation commands
│  └─ See: Quick Reference § Command Reference
│
├─ 📄 backstage-kind/Dockerfile.kind    # Production image
│  └─ See: Deployment Guide § Docker Build
│
├─ 📄 backstage-kind/app-config.yaml    # Base configuration
│  └─ Application settings
│
├─ 📄 backstage-kind/app-config.production.yaml
│  └─ Production overrides
│
├─ 📁 kubernetes/
│  ├─ namespace.yaml                    # Namespace definition
│  ├─ deployment.yaml                   # Main deployment
│  ├─ service.yaml                      # Service definition
│  ├─ ingress.yaml                      # Ingress with TLS
│  ├─ configmap.yaml                    # Environment variables
│  ├─ secrets.yaml                      # Sensitive data
│  └─ rbac.yaml                         # RBAC permissions
│
└─ 📁 helm/backstage/
   ├─ Chart.yaml                        # Chart metadata
   ├─ values.yaml                       # Configuration values
   └─ templates/                        # K8s templates
      ├─ _helpers.tpl
      ├─ deployment.yaml
      └─ service.yaml
```

### Configuration Precedence

```
Lowest Priority
    ↓
1. app-config.yaml (base config)
    ↓
2. app-config.production.yaml (overrides)
    ↓
3. kubernetes/configmap.yaml (env vars)
    ↓
4. kubernetes/secrets.yaml (sensitive data)
    ↓
5. Environment variables set in deployment
    ↓
Highest Priority
```

---

## 🎯 Common Tasks Quick Reference

### Build Tasks

| Task | Command | Documentation |
|------|---------|---------------|
| Install dependencies | `make install-deps` | [Deployment Guide](./DEPLOYMENT_GUIDE.md) |
| Build backend | `make build-backend` | [Deployment Guide](./DEPLOYMENT_GUIDE.md) |
| Build frontend | `make build-frontend` | [Deployment Guide](./DEPLOYMENT_GUIDE.md) |
| Build Docker image | `make build-docker` | [Deployment Guide](./DEPLOYMENT_GUIDE.md) |
| Push to registry | `make push-docker` | [Deployment Guide](./DEPLOYMENT_GUIDE.md) |

### Deployment Tasks

| Task | Command | Documentation |
|------|---------|---------------|
| Deploy with kubectl | `make deploy` | [Quick Reference](./QUICK_REFERENCE.md) |
| Install with Helm | `make helm-install` | [Quick Reference](./QUICK_REFERENCE.md) |
| Upgrade with Helm | `make helm-upgrade` | [Quick Reference](./QUICK_REFERENCE.md) |
| Restart app | `make restart` | [Quick Reference](./QUICK_REFERENCE.md) |

### Operational Tasks

| Task | Command | Documentation |
|------|---------|---------------|
| View logs | `make logs` | [Quick Reference](./QUICK_REFERENCE.md) |
| Port forward | `make port-forward` | [Quick Reference](./QUICK_REFERENCE.md) |
| Check status | `make status` | [Quick Reference](./QUICK_REFERENCE.md) |
| Clean builds | `make clean` | [Quick Reference](./QUICK_REFERENCE.md) |

---

## 📞 Support & Contributing

### Getting Help

1. **Check documentation** - Start with [Quick Reference](./QUICK_REFERENCE.md)
2. **Review logs** - `make logs`
3. **Check status** - `make status`
4. **Describe resources** - `make describe`

### Documentation Updates

When updating documentation:

1. Keep diagrams ASCII-art for portability
2. Use emojis for visual scanning
3. Include practical examples
4. Link between related sections
5. Update this index when adding new docs

---

## 📈 Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0.0 | 2025-01 | Initial documentation | DevOps Team |
| - v7 | 2025-01 | Docker image with dependencies | - |
| - Helm 1.0.0 | 2025-01 | Helm chart created | - |

---

## 🎉 Summary

This documentation provides:

- ✅ **3 comprehensive guides** covering deployment, operations, and architecture
- ✅ **Visual diagrams** for system understanding
- ✅ **Quick reference** for daily operations
- ✅ **Troubleshooting matrices** for problem resolution
- ✅ **Configuration examples** for all components
- ✅ **Learning paths** for different roles

**Total pages:** 4 major documents + configuration files
**Estimated reading time:** 2-3 hours for complete review
**Skill level:** Beginner to Advanced

---

**Made with ❤️ for the DevOps community**

*Last updated: January 2025*
