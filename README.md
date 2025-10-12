# 🚀 Backstage on Kind with GitOps

> **Developer Portal Completo con GitOps, CI/CD Automático, Monitoreo y App of Apps Pattern**

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Backstage](https://img.shields.io/badge/Backstage-9BF0E1?style=for-the-badge&logo=backstage&logoColor=black)](https://backstage.io/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)](https://argoproj.github.io/cd/)
[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)](https://prometheus.io/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)

---

## 📋 Tabla de Contenidos

- [Overview](#-overview)
- [Arquitectura](#-arquitectura)
- [Quick Start](#-quick-start)
- [Componentes](#-componentes)
- [ArgoCD App of Apps](#-argocd-app-of-apps)
- [Servicios](#-servicios)
- [Documentación](#-documentación)
- [Flujo GitOps](#-flujo-gitops)

---

## 🎯 Overview

Implementación completa de **Backstage** en Kubernetes (Kind) con patrón **App of Apps** de ArgoCD, gestionando toda la plataforma como código.

### ✨ Características Principales

- 🎯 **App of Apps Pattern** - Una aplicación raíz gestiona todas las demás
- 🔄 **GitOps con ArgoCD** - Todo versionado en Git, deployments automáticos
- 🚀 **CI/CD con GitHub Actions** - Build y push automático de imágenes
- 📊 **Monitoring Stack Completo** - Prometheus, Grafana, AlertManager
- 🐘 **PostgreSQL Gestionado** - Database con persistent storage y métricas
- 🔐 **GitHub OAuth** - Autenticación para ArgoCD y Grafana
- 🎨 **Dashboards Personalizados** - Alertas y visualizaciones para Backstage
- ⚡ **Sync Waves** - Orden de despliegue garantizado

---

## 🏗️ Arquitectura

### Diagrama de Alto Nivel

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Repository                        │
│  ┌──────────────┐  ┌────────────────┐  ┌────────────────┐ │
│  │ Application  │  │  Helm Charts   │  │ ArgoCD Apps    │ │
│  │    Code      │  │   (manifests)  │  │  (GitOps)      │ │
│  └──────────────┘  └────────────────┘  └────────────────┘ │
└─────────┬─────────────────┬────────────────────┬───────────┘
          │                 │                     │
          ▼                 │                     ▼
    GitHub Actions          │              ArgoCD Server
    (CI/CD Pipeline)        │            (App of Apps)
          │                 │                     │
          ▼                 │                     ▼
    Docker Hub              │         ┌───────────────────────┐
    (Images)                │         │  Sync Wave Orchestration │
          │                 │         ├───────────────────────┤
          │                 │         │ 1. PostgreSQL         │
          │                 ▼         │ 2. Backstage          │
          │         ArgoCD Image      │ 3. Ingress            │
          │         Updater           │ 4. Monitoring Stack   │
          │         (Auto-update)     │ 5. Monitoring Config  │
          │                 │         └───────────────────────┘
          └─────────────────┴───────────────┬─────────────────
                                             ▼
                                  ┌──────────────────────────┐
                                  │   Kubernetes Cluster     │
                                  │        (Kind)            │
                                  ├──────────────────────────┤
                                  │ Namespace: backstage     │
                                  │  ├─ Backstage Pod        │
                                  │  ├─ PostgreSQL           │
                                  │  └─ Ingress              │
                                  ├──────────────────────────┤
                                  │ Namespace: monitoring    │
                                  │  ├─ Prometheus (5Gi)     │
                                  │  ├─ Grafana (2Gi)        │
                                  │  ├─ AlertManager (1Gi)   │
                                  │  └─ Exporters            │
                                  ├──────────────────────────┤
                                  │ Namespace: argocd        │
                                  │  ├─ ArgoCD Server        │
                                  │  ├─ Image Updater        │
                                  │  └─ App Controller       │
                                  └──────────────────────────┘
```

### Flujo GitOps

```
Developer Push → GitHub → CI/CD Build → Docker Hub
                   │                        │
                   ▼                        ▼
         ArgoCD detect changes ← Image Updater
                   │
                   ▼
         Sync all applications in order (sync waves)
                   │
                   ▼
         Kubernetes applies changes → Rolling Update
```

---

## ⚡ Quick Start

### 📋 Prerequisitos

```bash
✅ Docker Desktop
✅ Kind
✅ kubectl
✅ Helm 3.x
✅ ArgoCD CLI (opcional)
✅ Git
```

### 🚀 Instalación Rápida (5 minutos)

```bash
# 1. Clonar repositorio
git clone https://github.com/Portfolio-jaime/backstage-kind-migration.git
cd backstage-kind-migration

# 2. Crear cluster Kind con ingress
make kind-create

# 3. Configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales:
# - GitHub OAuth App (client ID y secret)
# - Docker Hub credentials
# - PostgreSQL passwords

# 4. Crear secrets en Kubernetes
make create-secrets

# 5. Instalar ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 6. Configurar ArgoCD con GitHub OAuth y repo access
kubectl apply -f argocd/argocd-cm.yaml
kubectl apply -f argocd/argocd-rbac-cm.yaml
kubectl apply -f argocd/github-repo-secret.yaml

# 7. Desplegar App of Apps (esto despliega TODO)
kubectl apply -f argocd/root-application.yaml

# 8. Esperar a que todo se despliegue (2-5 minutos)
kubectl get application -n argocd -w
```

### ✅ Verificar Instalación

```bash
# Ver todas las aplicaciones de ArgoCD
kubectl get application -n argocd

# Debe mostrar:
# NAME                            SYNC STATUS   HEALTH STATUS
# backstage-platform              Synced        Healthy
# postgresql                      Synced        Healthy
# backstage                       Synced        Healthy
# backstage-ingress               Synced        Healthy
# kube-prometheus-stack           Synced        Healthy
# backstage-monitoring-config     Synced        Healthy

# Ver pods de Backstage
kubectl get pods -n backstage

# Ver pods de Monitoring
kubectl get pods -n monitoring
```

---

## 🎯 Componentes

### Stack Completo

| Componente | Versión | Namespace | Storage | Descripción |
|------------|---------|-----------|---------|-------------|
| **Backstage** | Latest | `backstage` | - | Developer Portal |
| **PostgreSQL** | 17.6.0 | `backstage` | 8Gi | Base de datos |
| **Prometheus** | Latest | `monitoring` | 5Gi | Métricas |
| **Grafana** | Latest | `monitoring` | 2Gi | Dashboards |
| **AlertManager** | Latest | `monitoring` | 1Gi | Alertas |
| **ArgoCD** | Latest | `argocd` | - | GitOps Controller |

### Persistent Storage Total

- **PostgreSQL**: 8Gi (expandible)
- **Prometheus**: 5Gi (automático por Operator)
- **Grafana**: 2Gi (dashboards y datasources)
- **AlertManager**: 1Gi (configuración de alertas)
- **Total**: ~16Gi

---

## 🎨 ArgoCD App of Apps

### Estructura de Aplicaciones

```
backstage-platform (Root Application)
│
├── 1️⃣ postgresql
│   ├── StatefulSet (1 replica)
│   ├── PVC (8Gi)
│   ├── Services (ClusterIP + Headless)
│   └── ServiceMonitor (métricas)
│
├── 2️⃣ backstage
│   ├── Deployment (1 replica)
│   ├── Service (ClusterIP)
│   ├── ConfigMaps (config)
│   └── Secrets (OAuth, DB)
│
├── 3️⃣ backstage-ingress
│   └── Ingress (nginx)
│       └── backstage.kind.local
│
├── 4️⃣ kube-prometheus-stack
│   ├── Prometheus + PVC (5Gi)
│   ├── Grafana + PVC (2Gi)
│   ├── AlertManager + PVC (1Gi)
│   ├── Prometheus Operator
│   ├── Node Exporter
│   └── Kube State Metrics
│
└── 5️⃣ backstage-monitoring-config
    ├── PrometheusRule (9 alertas)
    └── ConfigMap (dashboard)
```

### Sync Waves (Orden de Despliegue)

Los números indican el orden automático de despliegue:

1. **PostgreSQL** (wave 1) - Se despliega primero
2. **Backstage** (wave 2) - Espera a que PostgreSQL esté listo
3. **Ingress** (wave 3) - Se despliega después de Backstage
4. **Monitoring Stack** (wave 4) - Stack completo de monitoreo
5. **Monitoring Config** (wave 5) - Alertas y dashboards personalizados

### Desplegar Todo con Un Solo Comando

```bash
# Esto despliega automáticamente TODA la plataforma
kubectl apply -f argocd/root-application.yaml

# ArgoCD se encarga de:
# ✅ Desplegar en orden correcto (sync waves)
# ✅ Validar health de cada componente
# ✅ Hacer rollback automático si falla algo
# ✅ Mantener sincronizado con Git
```

---

## 🌐 Servicios

### URLs y Accesos

#### Con Port Forward

| Servicio | Comando | URL | Credenciales |
|----------|---------|-----|--------------|
| **Backstage** | `kubectl port-forward -n backstage svc/backstage 7007:80` | http://localhost:7007 | N/A (GitHub OAuth) |
| **ArgoCD** | `kubectl port-forward -n argocd svc/argocd-server 8080:443` | https://localhost:8080 | GitHub OAuth |
| **Grafana** | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80` | http://localhost:3000 | GitHub OAuth o admin/admin123 |
| **Prometheus** | `kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090` | http://localhost:9090 | N/A |
| **AlertManager** | `kubectl port-forward -n monitoring svc/prometheus-alertmanager 9093:9093` | http://localhost:9093 | N/A |

#### Con Ingress (Agregar a /etc/hosts)

```bash
echo "127.0.0.1 backstage.kind.local argocd.kind.local grafana.kind.local prometheus.kind.local" | sudo tee -a /etc/hosts
```

- **Backstage**: http://backstage.kind.local
- **ArgoCD**: http://argocd.kind.local
- **Grafana**: http://grafana.kind.local
- **Prometheus**: http://prometheus.kind.local

### Obtener Credenciales

```bash
# ArgoCD admin password (primera vez)
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# PostgreSQL password
kubectl get secret -n backstage backstage-secrets \
  -o jsonpath="{.data.POSTGRES_PASSWORD}" | base64 -d && echo

# Grafana admin password
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d && echo
```

---

## 📚 Documentación

### 📖 Guías Principales

#### Implementación GitOps

- **[argocd/README.md](argocd/README.md)** ⭐ - Guía completa de ArgoCD App of Apps
  - Estructura de aplicaciones
  - Sync waves y orden de despliegue
  - Health checks y troubleshooting
  - Gestión de secrets

#### Componentes

- **[helm-charts/postgresql/README.md](helm-charts/postgresql/README.md)** - PostgreSQL
  - Configuración y tuning
  - Backup y restore
  - Monitoreo con Prometheus
  - Operaciones comunes

- **[helm-charts/monitoring/README.md](helm-charts/monitoring/README.md)** - Monitoring Stack
  - Prometheus, Grafana, AlertManager
  - Dashboards personalizados
  - 9 alertas configuradas
  - Queries útiles

#### Monitoreo

- **[docs/MONITORING_SETUP_GUIDE.md](docs/MONITORING_SETUP_GUIDE.md)** - Configuración actual
  - Estado del stack
  - Acceso a servicios
  - Targets de Prometheus
  - Troubleshooting

- **[docs/MONITORING_IMPLEMENTATION.md](docs/MONITORING_IMPLEMENTATION.md)** - Implementación GitOps
  - Arquitectura de monitoring
  - Despliegue con ArgoCD
  - Flujo de actualizaciones

- **[docs/MONITORING_COMPLETE.md](docs/MONITORING_COMPLETE.md)** - Referencia completa
  - Stack desplegado
  - Métricas recolectadas
  - Dashboards disponibles

#### ArgoCD Configuration

- **[docs/ARGOCD_CONFIGURATION.md](docs/ARGOCD_CONFIGURATION.md)** - Configuración de ArgoCD
  - GitHub OAuth setup
  - RBAC policies
  - Secrets management

---

## 🔄 Flujo GitOps

### Desarrollo Diario

```bash
# 1. Hacer cambios en código de Backstage
cd backstage-kind/
# ... hacer cambios ...

# 2. Commit y push
git checkout -b feature/mi-cambio
git add .
git commit -m "feat: agregar nueva funcionalidad"
git push origin feature/mi-cambio

# 3. Crear PR y merge a main

# 4. ✨ AUTOMÁTICO:
#    ├─ GitHub Actions build imagen
#    ├─ Push a Docker Hub (jaimehenao8126/backstage-production)
#    ├─ ArgoCD Image Updater detecta nueva imagen (cada 2 min)
#    ├─ Image Updater actualiza helm-charts/backstage/values.yaml
#    ├─ Commit automático a Git
#    ├─ ArgoCD detecta cambio en Git
#    ├─ ArgoCD sincroniza (helm upgrade)
#    └─ Rolling update en Kubernetes ✅
```

### Actualizar Configuración (Helm Values)

```bash
# 1. Modificar configuración
vim helm-charts/postgresql/values.yaml
# Ejemplo: Aumentar memoria de PostgreSQL

# 2. Commit y push
git add helm-charts/postgresql/values.yaml
git commit -m "feat: aumentar memoria de PostgreSQL a 1Gi"
git push origin main

# 3. ✨ AUTOMÁTICO:
#    ├─ ArgoCD detecta cambio (cada 3 min)
#    ├─ ArgoCD sincroniza automáticamente
#    ├─ Helm upgrade con nuevos values
#    └─ Rolling update aplicado ✅
```

### Agregar Nueva Alerta

```bash
# 1. Editar alertas
vim helm-charts/monitoring/templates/backstage-alerts.yaml
# Agregar nueva alerta de PrometheusRule

# 2. Commit y push
git add helm-charts/monitoring/templates/backstage-alerts.yaml
git commit -m "feat: agregar alerta de high latency"
git push origin main

# 3. ✨ AUTOMÁTICO:
#    ├─ ArgoCD sincroniza backstage-monitoring-config
#    ├─ Aplica nuevo PrometheusRule
#    └─ Prometheus recarga reglas ✅
```

---

## 📁 Estructura del Proyecto

```
backstage-kind-migration/
│
├── argocd/                               # 🎯 ArgoCD GitOps
│   ├── README.md                         # Guía de ArgoCD
│   ├── root-application.yaml             # 🌟 App of Apps Principal
│   ├── apps/                             # Todas las aplicaciones
│   │   ├── postgresql-application.yaml
│   │   ├── backstage-application.yaml
│   │   ├── ingress-application.yaml
│   │   ├── monitoring-application.yaml
│   │   └── monitoring-config-application.yaml
│   ├── argocd-cm.yaml                    # ArgoCD config (GitHub OAuth)
│   ├── argocd-rbac-cm.yaml              # RBAC policies
│   ├── github-repo-secret.yaml          # Repo access
│   └── image-updater-config.yaml        # Image updater

│
├── helm-charts/                          # 📦 Helm Charts
│   ├── backstage/                        # Backstage app
│   │   ├── Chart.yaml
│   │   ├── values.yaml                   # 🎯 GitOps Source of Truth
│   │   └── templates/
│   ├── postgresql/                       # PostgreSQL 17.6.0
│   │   ├── Chart.yaml
│   │   ├── values.yaml                   # DB configuration
│   │   ├── README.md                     # Operación de PostgreSQL
│   │   └── templates/
│   ├── monitoring/                       # Monitoring stack
│   │   ├── Chart.yaml
│   │   ├── values.yaml                   # Prometheus + Grafana config
│   │   ├── README.md                     # Guía de monitoring
│   │   └── templates/
│   │       ├── backstage-alerts.yaml     # 9 alertas
│   │       ├── backstage-dashboard.json  # Dashboard personalizado
│   │       └── backstage-dashboard-configmap.yaml
│   └── ingress/                          # Ingress configs
│       ├── Chart.yaml
│       └── templates/
│           └── backstage-ingress.yaml
│
├── backstage-kind/                       # 💻 Backstage Source Code
│   ├── packages/app/                     # Frontend
│   ├── packages/backend/                 # Backend
│   ├── app-config.yaml                   # Backstage config
│   └── Dockerfile.kind                   # Production Dockerfile
│
├── docs/                                 # 📚 Documentation
│   ├── MONITORING_SETUP_GUIDE.md         # Setup actual
│   ├── MONITORING_IMPLEMENTATION.md      # GitOps implementation
│   ├── MONITORING_COMPLETE.md            # Referencia completa
│   ├── ARGOCD_CONFIGURATION.md           # ArgoCD config
│   ├── PROJECT_SETUP.md                  # Setup del proyecto
│   └── GITOPS_ARGOCD.md                  # GitOps guide
│
├── .github/workflows/
│   └── ci-cd.yaml                        # 🚀 CI/CD Pipeline
│
├── scripts/
│   ├── setup-argocd.sh                   # ArgoCD setup
│   └── upload-secrets.sh                 # GitHub secrets upload
│
├── .env.example                          # Template de variables
├── Makefile                              # 🛠️ Helper commands
└── README.md                             # 📖 Este archivo
```

---

## 🛠️ Comandos Útiles

### Cluster Management

```bash
make kind-create          # Crear cluster Kind
make kind-delete          # Eliminar cluster
make kind-status          # Ver estado del cluster
```

### ArgoCD

```bash
# Ver todas las aplicaciones
kubectl get application -n argocd
argocd app list

# Ver árbol de aplicaciones (App of Apps)
argocd app tree backstage-platform

# Sincronizar aplicación específica
argocd app sync postgresql
argocd app sync backstage

# Sincronizar toda la plataforma
argocd app sync backstage-platform

# Ver logs de sync
argocd app logs backstage --follow

# Ver diff con Git
argocd app diff backstage
```

### Monitoring

```bash
# Ver pods de monitoring
kubectl get pods -n monitoring

# Ver todas las métricas de Prometheus
kubectl get servicemonitor -A

# Ver alertas configuradas
kubectl get prometheusrule -n monitoring

# Ver PVCs (persistent storage)
kubectl get pvc -n monitoring
kubectl get pvc -n backstage

# Port forward a servicios
make port-forward-grafana
make port-forward-prometheus
make port-forward-backstage
```

### PostgreSQL

```bash
# Conectarse a PostgreSQL
kubectl exec -it -n backstage psql-postgresql-0 -- psql -U backstage -d backstage

# Ver tamaño de base de datos
kubectl exec -n backstage psql-postgresql-0 -- \
  psql -U backstage -d backstage -c \
  "SELECT pg_size_pretty(pg_database_size('backstage'));"

# Backup de base de datos
kubectl exec -n backstage psql-postgresql-0 -- \
  pg_dump -U backstage backstage > backup-$(date +%Y%m%d).sql

# Ver logs
kubectl logs -n backstage psql-postgresql-0 -f
```

### Troubleshooting

```bash
# Ver eventos recientes
kubectl get events -n backstage --sort-by='.lastTimestamp'
kubectl get events -n monitoring --sort-by='.lastTimestamp'

# Ver logs de aplicación
kubectl logs -n backstage -l app=backstage -f

# Ver estado de ArgoCD sync
kubectl describe application backstage -n argocd

# Ver logs de Image Updater
kubectl logs -n argocd deployment/argocd-image-updater -f

# Describir pod con problemas
kubectl describe pod <pod-name> -n backstage
```

---

## 🔐 Seguridad

### Secrets Management

- ✅ **GitHub Secrets**: CI/CD credentials
- ✅ **Kubernetes Secrets**: Runtime credentials
- ✅ **GitHub OAuth**: ArgoCD y Grafana authentication
- ✅ **RBAC**: Control de acceso basado en roles
- ❌ **NUNCA** commitear `.env` o secrets a Git

### GitHub OAuth Apps

**ArgoCD + Grafana** usan el mismo OAuth App:
- **Client ID**: `Ov23liX98Qe1ectC1zdj`
- **Organization**: `Portfolio-jaime`
- **Callbacks**:
  - ArgoCD: `https://argocd.kind.local/api/dex/callback`
  - Grafana: `http://grafana.kind.local/login/github`

---

## 📊 Estado del Proyecto

### ✅ Completado

- [x] App of Apps pattern implementado
- [x] PostgreSQL gestionado con GitOps
- [x] Monitoring stack completo (Prometheus, Grafana, AlertManager)
- [x] 9 Alertas personalizadas para Backstage
- [x] Dashboard personalizado de Grafana
- [x] Persistent storage para todos los componentes
- [x] GitHub OAuth para ArgoCD y Grafana
- [x] Sync waves para orden de despliegue
- [x] CI/CD con GitHub Actions
- [x] Image Updater configurado
- [x] Documentación completa

### 🎯 En Producción

- **Repository**: https://github.com/Portfolio-jaime/backstage-kind-migration
- **Docker Images**: `jaimehenao8126/backstage-production`
- **ArgoCD**: App of Apps pattern activo
- **Auto-sync**: Habilitado para todas las aplicaciones
- **Self-heal**: Habilitado (recuperación automática)

### 🚀 Próximos Pasos

1. **Métricas de Backstage**
   - Instalar plugin `@backstage/plugin-prometheus`
   - Configurar endpoint `/metrics`

2. **Notificaciones**
   - Configurar Slack para AlertManager
   - Email para alertas críticas

3. **Dashboards Adicionales**
   - Dashboard de PostgreSQL
   - Dashboard de ArgoCD
   - SLOs y SLIs

4. **Sealed Secrets**
   - Versionar secrets de forma segura en Git

---

## 📧 Contacto

**Maintainer**: Jaime Henao
**Email**: jaime.andres.henao.arbelaez@ba.com
**GitHub**: https://github.com/Portfolio-jaime
**Repository**: https://github.com/Portfolio-jaime/backstage-kind-migration

---

**🚀 Platform as Code - Everything in Git!**

*Última actualización: Octubre 11, 2025*
