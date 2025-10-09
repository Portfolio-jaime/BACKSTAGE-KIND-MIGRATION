# 🚀 Backstage Platform on Kind - Complete Setup

> **Developer Portal con Stack Completo de Observabilidad y GitOps**

[![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Backstage](https://img.shields.io/badge/Backstage-9BF0E1?style=for-the-badge&logo=backstage&logoColor=black)](https://backstage.io/)
[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)](https://prometheus.io/)
[![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)](https://grafana.com/)
[![ArgoCD](https://img.shields.io/badge/ArgoCD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white)](https://argoproj.github.io/cd/)

---

## 📖 Tabla de Contenidos

- [Overview](#-overview)
- [Arquitectura](#-arquitectura)
- [Quick Start](#-quick-start)
- [Servicios Desplegados](#-servicios-desplegados)
- [Acceso](#-acceso)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Documentación](#-documentación)
- [Troubleshooting](#-troubleshooting)

---

## 🎯 Overview

Este proyecto despliega un **Developer Portal completo** basado en Backstage con un stack de observabilidad y GitOps en un cluster local de Kubernetes (Kind).

### ✨ Características Principales

- 🏠 **Backstage** - Developer Portal con catálogo de servicios
- 📊 **Prometheus** - Recolección de métricas
- 📈 **Grafana** - Dashboards y visualización
- 🔄 **ArgoCD** - GitOps continuous delivery
- 🚨 **AlertManager** - Gestión de alertas
- 🗄️ **PostgreSQL** - Base de datos para Backstage
- 🌐 **NGINX Ingress** - Ingress Controller

### 🎨 Custom Pages en Backstage

- `/prometheus` - Monitoring y métricas
- `/grafana` - Dashboards y visualización
- `/argocd` - GitOps deployments
- `/kubernetes` - Cluster management

---

## 🏗️ Arquitectura

```
┌──────────────────────────────────────────────────────────┐
│                 Backstage Developer Portal                │
│              http://backstage.kind.local                  │
└──────────────────────────────────────────────────────────┘
                          │
                          ├─────────────────────────┐
                          │                         │
          ┌───────────────┴────────┐    ┌──────────┴──────────┐
          │   Monitoring Stack     │    │  GitOps Platform    │
          │   (monitoring ns)      │    │   (argocd ns)       │
          │                        │    │                     │
          │  • Prometheus :9090    │    │  • ArgoCD :443      │
          │  • Grafana :80         │    │  • Repo Server      │
          │  • AlertManager :9093  │    │  • App Controller   │
          └────────────────────────┘    └─────────────────────┘
                          │
          ┌───────────────┴────────────────────────┐
          │     Kind Kubernetes Cluster            │
          │     • 1 Control Plane Node             │
          │     • NGINX Ingress Controller         │
          │     • Resource Quotas Configured       │
          └────────────────────────────────────────┘
```

---

## ⚡ Quick Start

### Prerrequisitos

```bash
# Verificar instalaciones
docker --version          # Docker 20.10+
kind --version           # Kind 0.20+
kubectl version         # Kubectl 1.27+
helm version            # Helm 3.12+
```

### Instalación Rápida

```bash
# 1. Clonar repositorio
git clone <repo-url>
cd backstage-kind-migration

# 2. Crear cluster Kind
kind create cluster --name kind

# 3. Instalar NGINX Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# 4. Esperar a que NGINX esté listo
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# 5. Desplegar Monitoring Stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# 6. Desplegar ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 7. Desplegar Backstage
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/secrets.yaml
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/rbac.yaml
kubectl apply -f kubernetes/simple-deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/ingress.yaml

# 8. Aplicar Ingresses
kubectl apply -f kubernetes/monitoring-ingresses.yaml
kubectl apply -f kubernetes/argocd-ingress.yaml

# 9. Configurar DNS local
sudo nano /etc/hosts
# Agregar:
# 127.0.0.1 backstage.kind.local prometheus.kind.local grafana.kind.local argocd.kind.local alertmanager.kind.local

# 10. Verificar
kubectl get pods --all-namespaces
```

---

## 🌐 Servicios Desplegados

### URLs de Acceso

| Servicio | URL | Namespace | Descripción |
|----------|-----|-----------|-------------|
| **Backstage** | http://backstage.kind.local | `backstage` | Developer Portal |
| **Prometheus** | http://prometheus.kind.local | `monitoring` | Metrics & Monitoring |
| **Grafana** | http://grafana.kind.local | `monitoring` | Dashboards |
| **ArgoCD** | http://argocd.kind.local | `argocd` | GitOps CD |
| **AlertManager** | http://alertmanager.kind.local | `monitoring` | Alert Management |

---

## 🔑 Acceso

### Credenciales

#### Grafana
```bash
# Usuario: admin
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d && echo
```

#### ArgoCD
```bash
# Usuario: admin
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

#### PostgreSQL (Backstage)
```bash
# Usuario: backstage
kubectl get secret -n backstage psql-postgresql \
  -o jsonpath="{.data.postgres-password}" | base64 -d && echo
```

---

## 📁 Estructura del Proyecto

```
backstage-kind-migration/
├── README.md                          # Este archivo
├── docs/
│   ├── PLATFORM_MONITORING_GUIDE.md   # Guía completa
│   ├── MIGRATION_PLAN.md              # Plan de migración
│   └── CLUSTER_STATUS.md              # Estado del cluster
├── kubernetes/
│   ├── namespace.yaml                 # Namespace de Backstage
│   ├── secrets.yaml                   # Secrets (Git, DB, etc)
│   ├── configmap.yaml                 # ConfigMap de Backstage
│   ├── rbac.yaml                      # ServiceAccount, Role, Binding
│   ├── simple-deployment.yaml         # Deployment de Backstage
│   ├── service.yaml                   # Service ClusterIP
│   ├── ingress.yaml                   # Ingress para Backstage
│   ├── monitoring-ingresses.yaml      # Ingresses para Prometheus/Grafana
│   └── argocd-ingress.yaml            # Ingress para ArgoCD
├── backstage-catalog/
│   └── platform-services.yaml         # Catálogo de servicios
└── scripts/
    ├── 01-setup-kind.sh               # Crear cluster
    ├── 02-install-ingress.sh          # Instalar NGINX
    ├── 03-deploy-backstage.sh         # Desplegar Backstage
    ├── 04-verify-deployment.sh        # Verificar deployment
    └── 05-update-existing-deployment.sh # Actualizar existente
```

---

## 📚 Documentación

### Guías Disponibles

1. **[Platform Monitoring Guide](docs/PLATFORM_MONITORING_GUIDE.md)** ⭐
   - Arquitectura completa con diagramas
   - Guías de implementación paso a paso
   - Troubleshooting detallado
   - Comandos útiles

2. **[Migration Plan](docs/MIGRATION_PLAN.md)**
   - Plan de migración completo
   - Checklist de tareas
   - Rollback procedures

3. **[Cluster Status](docs/CLUSTER_STATUS.md)**
   - Estado actual del cluster
   - Recursos desplegados
   - Métricas y quotas

---

## 🔧 Troubleshooting

### Comandos Útiles

```bash
# Ver logs de Backstage
kubectl logs -f deployment/backstage -n backstage

# Restart Backstage
kubectl rollout restart deployment/backstage -n backstage

# Ver eventos
kubectl get events -n backstage --sort-by='.lastTimestamp'

# Ver resource quota
kubectl describe resourcequota backstage-quota -n backstage
```

### Problemas Comunes

#### Pod no inicia
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

#### Ingress 404/502
```bash
kubectl get ingress -n <namespace>
kubectl describe ingress <ingress-name> -n <namespace>
cat /etc/hosts | grep kind.local
```

---

## 📊 Páginas de Backstage

El sistema incluye páginas personalizadas para cada servicio de plataforma:

- **`/prometheus`** - Métricas y monitoring
- **`/grafana`** - Dashboards y visualización
- **`/argocd`** - GitOps deployments
- **`/kubernetes`** - Cluster management

Todas accesibles desde http://backstage.kind.local

---

## 🎯 Estado del Proyecto

### ✅ Completado

- [x] Backstage desplegado con 1 réplica
- [x] PostgreSQL funcionando
- [x] Prometheus + Grafana + AlertManager
- [x] ArgoCD GitOps
- [x] Ingresses configurados (.kind.local)
- [x] Resource Quotas (3 CPU, 6Gi RAM)
- [x] Catálogo de servicios de plataforma
- [x] Custom Pages para cada servicio
- [x] Documentación completa

### 🚧 En Progreso

- [ ] Push de páginas al repositorio Git
- [ ] Configuración de alertas
- [ ] Dashboards custom en Grafana

---

## 📧 Contacto

**Platform Engineering Team**
- Email: platform-engineering@ba.com
- Backstage: http://backstage.kind.local

---

**🚀 Happy Coding!**

*Última actualización: Octubre 6, 2025*
