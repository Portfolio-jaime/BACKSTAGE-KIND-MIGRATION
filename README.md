# 🚀 Backstage on Kind with GitOps

> **Developer Portal con CI/CD automático, GitOps y Monitoreo**

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Backstage](https://img.shields.io/badge/Backstage-9BF0E1?style=for-the-badge&logo=backstage&logoColor=black)](https://backstage.io/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)](https://argoproj.github.io/cd/)
[![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white)](https://github.com/features/actions)

---

## 📋 Tabla de Contenidos

- [Overview](#-overview)
- [Arquitectura](#-arquitectura)
- [Quick Start](#-quick-start)
- [Servicios](#-servicios)
- [Documentación](#-documentación)
- [Flujo de Trabajo](#-flujo-de-trabajo)

---

## 🎯 Overview

Implementación completa de **Backstage** en Kubernetes (Kind) con:

### ✨ Características

- 🔄 **GitOps con ArgoCD** - Deployments automáticos desde Git
- 🚀 **CI/CD con GitHub Actions** - Build y push automático de imágenes
- 📊 **Monitoreo con Prometheus + Grafana**
- 🗄️ **PostgreSQL** - Base de datos en cluster
- 🔐 **Gestión segura de secrets**
- 🎯 **Auto-sync** - Actualización automática con nuevas imágenes

---

## 🏗️ Arquitectura

```
Developer Push Code
        │
        ▼
   GitHub Repository
        │
        ├─> GitHub Actions
        │   ├─ Build & Test
        │   └─ Push to Docker Hub
        │       │
        ▼       ▼
ArgoCD Image Updater (cada 2 min)
        │
        ├─ Detecta nueva imagen
        ├─ Actualiza values.yaml en Git
        └─ Commit automático
                │
                ▼
        ArgoCD (auto-sync)
                │
                ├─ Helm upgrade
                └─ Rolling update
                        │
                        ▼
                Kubernetes (Kind)
                        │
                        ├─ Backstage Pod
                        ├─ PostgreSQL
                        └─ Prometheus + Grafana
```

---

## ⚡ Quick Start

### 1. Prerrequisitos

```bash
# Instalar herramientas
- Docker Desktop
- Kind
- kubectl
- Helm 3
- Node.js 20+
- Yarn
```

### 2. Setup Rápido

```bash
# 1. Crear cluster Kind
make kind-create

# 2. Configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales

# 3. Desplegar PostgreSQL
make deploy-postgres

# 4. Crear secrets
make create-secrets

# 5. Instalar ArgoCD y configurar GitOps
chmod +x scripts/setup-argocd.sh
./scripts/setup-argocd.sh

# 6. Build y push imagen inicial
make build-docker
docker push jaimehenao8126/backstage-production:latest
```

### 3. Configurar GitHub Secrets

```bash
# Upload secrets a GitHub para CI/CD
chmod +x scripts/upload-secrets.sh
./scripts/upload-secrets.sh
```

### 4. Verificar Deployment

```bash
# Ver estado de ArgoCD
kubectl get application backstage -n argocd

# Ver pods
kubectl get pods -n backstage

# Acceder a Backstage
kubectl port-forward -n backstage svc/backstage 7007:80
# http://localhost:7007
```

---

## 🌐 Servicios

### URLs y Accesos

| Servicio | Port Forward | Credenciales |
|----------|-------------|--------------|
| **Backstage** | `kubectl port-forward -n backstage svc/backstage 7007:80` | N/A |
| **ArgoCD** | `kubectl port-forward -n argocd svc/argocd-server 8080:443` | `admin` / [ver abajo](#credenciales) |
| **Grafana** | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80` | `admin` / `prom-operator` |
| **Prometheus** | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090` | N/A |

### Credenciales

```bash
# ArgoCD admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# PostgreSQL password
kubectl get secret -n backstage backstage-secrets \
  -o jsonpath="{.data.POSTGRES_PASSWORD}" | base64 -d && echo
```

---

## 📚 Documentación

### Guías Principales

1. **[Project Setup](docs/PROJECT_SETUP.md)** ⭐
   - Configuración completa del proyecto
   - Arquitectura detallada
   - Todos los comandos necesarios
   - Troubleshooting

2. **[GitOps con ArgoCD](docs/GITOPS_ARGOCD.md)**
   - Flujo GitOps completo
   - Configuración de Image Updater
   - Monitoreo y alertas
   - Best practices

3. **[Architecture Diagrams](docs/ARCHITECTURE_DIAGRAMS.md)**
   - Diagramas visuales
   - Flujos de datos
   - Componentes del sistema

### Guías Adicionales

- `docs/DEPLOYMENT_GUIDE.md` - Guía de deployment
- `docs/PLATFORM_MONITORING_GUIDE.md` - Monitoreo
- `docs/BACKSTAGE_CONFIGURATION_GUIDE.md` - Configuración de Backstage

---

## 🔄 Flujo de Trabajo

### Desarrollo Diario

```bash
# 1. Hacer cambios en backstage-kind/
git checkout -b feature/mi-cambio
# ... hacer cambios ...

# 2. Commit y push
git add .
git commit -m "feat: nuevo cambio"
git push origin feature/mi-cambio

# 3. Crear PR y merge a main

# 4. ✨ AUTOMÁTICO desde aquí:
#    - GitHub Actions build imagen
#    - Push a Docker Hub
#    - ArgoCD Image Updater detecta cambio
#    - ArgoCD aplica cambios
#    - Rolling update en K8s
```

### Verificar Deployment

```bash
# Ver en ArgoCD UI
kubectl port-forward -n argocd svc/argocd-server 8080:443
# https://localhost:8080

# O por línea de comandos
kubectl get application backstage -n argocd
kubectl get pods -n backstage -w
```

---

## 📁 Estructura del Proyecto

```
backstage-kind-migration/
├── .github/workflows/
│   └── ci-cd.yaml                    # 🚀 CI/CD Pipeline
│
├── argocd/
│   ├── backstage-application.yaml    # 🎯 ArgoCD App
│   ├── image-updater-config.yaml     # 🔄 Image Updater
│   └── github-repo-secret.yaml       # 🔐 GitHub Auth
│
├── backstage-kind/                   # 💻 Backstage Source
│   ├── packages/app/                 # Frontend
│   ├── packages/backend/             # Backend
│   ├── app-config.yaml               # Config
│   └── Dockerfile.kind               # Dockerfile
│
├── helm/backstage/                   # ⎈ Helm Chart
│   ├── Chart.yaml
│   ├── values.yaml                   # 🎯 GitOps Source of Truth
│   └── templates/
│
├── docs/                             # 📚 Documentation
│   ├── PROJECT_SETUP.md              # ⭐ Guía Principal
│   ├── GITOPS_ARGOCD.md             # GitOps Guide
│   └── ...
│
├── scripts/
│   ├── setup-argocd.sh              # ArgoCD Setup
│   └── upload-secrets.sh            # GitHub Secrets
│
└── Makefile                         # 🛠️ Helper Commands
```

---

## 🛠️ Comandos Útiles

```bash
# Cluster Management
make kind-create          # Crear cluster
make kind-delete          # Eliminar cluster
make kind-status          # Ver estado

# Build & Deploy
make build-docker         # Build imagen local
make load-image          # Load en Kind
make helm-install        # Instalar con Helm
make helm-upgrade        # Upgrade deployment

# Monitoring
kubectl get all -n backstage                    # Ver recursos
kubectl logs -n backstage -l app=backstage -f   # Ver logs
kubectl get application -n argocd               # ArgoCD apps

# Troubleshooting
kubectl describe pod <pod-name> -n backstage
kubectl get events -n backstage --sort-by='.lastTimestamp'
kubectl logs -n argocd deployment/argocd-image-updater -f
```

---

## 🔐 Seguridad

- ✅ Secrets en GitHub Secrets (CI/CD)
- ✅ Secrets en Kubernetes (Runtime)
- ✅ GitHub Token para ArgoCD write-back
- ✅ Docker Hub credentials en Image Updater
- ❌ **NUNCA** commitear `.env` a Git

---

## 📊 Estado del Proyecto

### ✅ Completado

- [x] Backstage desplegado y funcional
- [x] PostgreSQL en cluster
- [x] CI/CD con GitHub Actions
- [x] GitOps con ArgoCD
- [x] Image Updater configurado
- [x] Auto-sync habilitado
- [x] Monitoreo con Prometheus + Grafana
- [x] Helm Chart completo
- [x] Documentación completa

### 🎯 En Uso

**Repositorio Git**: https://github.com/Portfolio-jaime/BACKSTAGE-KIND-MIGRATION
**Docker Hub**: `jaimehenao8126/backstage-production:latest`
**ArgoCD**: Configurado con auto-sync + self-heal
**Image Updater**: Polling cada 2 minutos

---

## 🚀 Próximos Pasos

1. Hacer cambio en código
2. Push a `main`
3. Esperar ~5 min (CI/CD + ArgoCD)
4. Verificar en ArgoCD UI
5. Probar en http://localhost:7007

---

## 📧 Contacto

**Maintainer**: Jaime Henao
**Email**: jaime.andres.henao.arbelaez@ba.com
**GitHub**: https://github.com/Portfolio-jaime

---

**🚀 Happy Coding!**

*Última actualización: Octubre 11, 2025*
