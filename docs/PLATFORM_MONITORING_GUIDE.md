# 📊 Platform Monitoring & Observability Guide

**Autor**: Platform Engineering Team
**Fecha**: Octubre 6, 2025
**Versión**: 1.0.0

---

## 📑 Tabla de Contenidos

1. [Arquitectura General](#arquitectura-general)
2. [Componentes del Sistema](#componentes-del-sistema)
3. [Guía de Implementación](#guía-de-implementación)
4. [Acceso a Servicios](#acceso-a-servicios)
5. [Guías de Uso](#guías-de-uso)
6. [Troubleshooting](#troubleshooting)
7. [Diagramas](#diagramas)

---

## 🏗️ Arquitectura General

### Stack Completo

```
┌─────────────────────────────────────────────────────────────┐
│                    Backstage Portal                          │
│                 http://backstage.kind.local                  │
│  ┌────────────┬────────────┬────────────┬────────────┐     │
│  │ Prometheus │  Grafana   │  ArgoCD    │ Kubernetes │     │
│  │   Page     │   Page     │   Page     │   Page     │     │
│  └────────────┴────────────┴────────────┴────────────┘     │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                 NGINX Ingress Controller                     │
│                                                              │
│  ┌──────────────┬──────────────┬──────────────┬─────────┐  │
│  │   Backstage  │  Prometheus  │   Grafana    │ ArgoCD  │  │
│  │ .kind.local  │ .kind.local  │ .kind.local  │.kind... │  │
│  └──────────────┴──────────────┴──────────────┴─────────┘  │
└─────────────────────────────────────────────────────────────┘
                          │
         ┌────────────────┼────────────────┐
         ▼                ▼                ▼
┌─────────────────┐ ┌──────────────┐ ┌──────────────┐
│   Monitoring    │ │  ArgoCD      │ │  Backstage   │
│   Namespace     │ │  Namespace   │ │  Namespace   │
│                 │ │              │ │              │
│ • Prometheus    │ │ • ArgoCD     │ │ • Backstage  │
│ • Grafana       │ │ • Repo Srv   │ │ • PostgreSQL │
│ • AlertManager  │ │ • App Ctrl   │ │              │
│ • Node Exporter │ │ • Redis      │ │              │
└─────────────────┘ └──────────────┘ └──────────────┘
         │                │                │
         └────────────────┴────────────────┘
                     ▼
         ┌────────────────────────┐
         │  Kind Kubernetes       │
         │  Control Plane Node    │
         └────────────────────────┘
```

### Flujo de Datos

```
Metrics Flow:
  Services → Prometheus → Grafana → User

GitOps Flow:
  Git Repo → ArgoCD → Kubernetes → Application

Alerts Flow:
  Prometheus → AlertManager → Notifications
```

---

## 🧩 Componentes del Sistema

### 1. **Prometheus** 📈

**Propósito**: Recolección y almacenamiento de métricas

**Características**:
- Time-series database
- PromQL query language
- Service discovery
- Alert rules

**Recursos Kubernetes**:
```yaml
Namespace: monitoring
Deployment: prometheus-prometheus-0
Service: prometheus-prometheus:9090
Ingress: prometheus.kind.local
```

**Métricas Recolectadas**:
- Container metrics (CPU, Memory, Network)
- Kubernetes metrics (Pods, Nodes, Deployments)
- Application metrics (custom exporters)
- Node metrics (via Node Exporter)

---

### 2. **Grafana** 📊

**Propósito**: Visualización de métricas y dashboards

**Características**:
- Interactive dashboards
- Multiple data sources
- Alert visualization
- User-friendly interface

**Recursos Kubernetes**:
```yaml
Namespace: monitoring
Deployment: kube-prometheus-stack-grafana
Service: kube-prometheus-stack-grafana:80
Ingress: grafana.kind.local
```

**Data Sources Configuradas**:
- Prometheus (primary)
- Kubernetes API

---

### 3. **ArgoCD** 🔄

**Propósito**: GitOps continuous delivery

**Características**:
- Declarative GitOps
- Automated sync
- Rollback capabilities
- Multi-cluster support

**Recursos Kubernetes**:
```yaml
Namespace: argocd
Server: argocd-server:443
Repo Server: argocd-repo-server:8081
App Controller: argocd-application-controller
Ingress: argocd.kind.local
```

**Aplicaciones Gestionadas**:
- Backstage
- Monitoring stack
- Custom applications

---

### 4. **AlertManager** 🚨

**Propósito**: Gestión y enrutamiento de alertas

**Características**:
- Alert grouping
- Silencing
- Routing
- Integrations (Slack, Email, etc.)

**Recursos Kubernetes**:
```yaml
Namespace: monitoring
StatefulSet: alertmanager-prometheus-alertmanager-0
Service: prometheus-alertmanager:9093
Ingress: alertmanager.kind.local
```

---

### 5. **Backstage** 🏠

**Propósito**: Developer portal y service catalog

**Características**:
- Service catalog
- TechDocs
- Software templates
- Custom pages

**Recursos Kubernetes**:
```yaml
Namespace: backstage
Deployment: backstage (1 replica)
Service: backstage:80
Database: psql-postgresql (StatefulSet)
Ingress: backstage.kind.local
```

---

## 🚀 Guía de Implementación

### Paso 1: Verificar Pre-requisitos

```bash
# Verificar Kind cluster
kind get clusters

# Verificar kubectl
kubectl cluster-info

# Verificar namespaces
kubectl get namespaces
```

**Namespaces requeridos**:
- `monitoring` ✅
- `argocd` ✅
- `backstage` ✅

---

### Paso 2: Desplegar Ingress Controller

```bash
# Verificar NGINX Ingress
kubectl get pods -n ingress-nginx

# Si no está instalado:
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Esperar a que esté listo
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

---

### Paso 3: Desplegar Monitoring Stack

```bash
# Agregar repositorio Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Instalar kube-prometheus-stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword=admin

# Verificar instalación
kubectl get pods -n monitoring
```

---

### Paso 4: Desplegar ArgoCD

```bash
# Crear namespace
kubectl create namespace argocd

# Instalar ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Esperar a que esté listo
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-server -n argocd

# Obtener password inicial
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

---

### Paso 5: Desplegar Backstage

```bash
# Aplicar namespace
kubectl apply -f kubernetes/namespace.yaml

# Aplicar secrets y configmaps
kubectl apply -f kubernetes/secrets.yaml
kubectl apply -f kubernetes/configmap.yaml

# Aplicar RBAC
kubectl apply -f kubernetes/rbac.yaml

# Aplicar deployment y service
kubectl apply -f kubernetes/simple-deployment.yaml
kubectl apply -f kubernetes/service.yaml

# Aplicar ingress
kubectl apply -f kubernetes/ingress.yaml

# Verificar
kubectl get pods -n backstage
```

---

### Paso 6: Configurar Ingresses

```bash
# Aplicar ingresses para monitoring
kubectl apply -f kubernetes/monitoring-ingresses.yaml

# Aplicar ingress para ArgoCD
kubectl apply -f kubernetes/argocd-ingress.yaml

# Verificar todos los ingresses
kubectl get ingress --all-namespaces
```

**Expected Output**:
```
NAMESPACE    NAME           HOSTS                    ADDRESS
argocd       argocd-server  argocd.kind.local        localhost
backstage    backstage      backstage.kind.local     localhost
monitoring   prometheus     prometheus.kind.local    localhost
monitoring   grafana        grafana.kind.local       localhost
monitoring   alertmanager   alertmanager.kind.local  localhost
```

---

### Paso 7: Configurar DNS Local

Agregar a `/etc/hosts`:

```bash
127.0.0.1 backstage.kind.local
127.0.0.1 prometheus.kind.local
127.0.0.1 grafana.kind.local
127.0.0.1 argocd.kind.local
127.0.0.1 alertmanager.kind.local
```

**macOS/Linux**:
```bash
sudo nano /etc/hosts
```

**Windows**:
```
C:\Windows\System32\drivers\etc\hosts
```

---

### Paso 8: Agregar Páginas a Backstage

```bash
# Montar catálogo de servicios de plataforma
kubectl create configmap backstage-platform-catalog \
  -n backstage \
  --from-file=platform-services.yaml=backstage-catalog/platform-services.yaml

# Actualizar deployment para montar el catálogo
kubectl patch deployment backstage -n backstage --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes/-",
    "value": {
      "name": "platform-services",
      "configMap": {"name": "backstage-platform-catalog"}
    }
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts/-",
    "value": {
      "name": "platform-services",
      "mountPath": "/app/catalog/platform-services.yaml",
      "subPath": "platform-services.yaml"
    }
  }
]'

# Actualizar configuración para cargar el catálogo
# (Ver archivo de configuración)

# Reiniciar Backstage
kubectl delete pod -n backstage -l app=backstage
```

---

## 🌐 Acceso a Servicios

### URLs de Acceso

| Servicio | URL | Puerto | Propósito |
|----------|-----|--------|-----------|
| **Backstage** | http://backstage.kind.local | 80 | Developer Portal |
| **Prometheus** | http://prometheus.kind.local | 80 | Metrics & Monitoring |
| **Grafana** | http://grafana.kind.local | 80 | Dashboards |
| **ArgoCD** | http://argocd.kind.local | 80/443 | GitOps |
| **AlertManager** | http://alertmanager.kind.local | 80 | Alert Management |

---

### Credenciales de Acceso

#### Grafana
```bash
# Usuario: admin
# Password:
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d
echo
```

#### ArgoCD
```bash
# Usuario: admin
# Password:
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo
```

#### PostgreSQL (Backstage)
```bash
# Usuario: backstage
# Password:
kubectl get secret -n backstage psql-postgresql \
  -o jsonpath="{.data.postgres-password}" | base64 -d
echo
```

---

## 📖 Guías de Uso

### Prometheus

#### Consultar Métricas
1. Abrir http://prometheus.kind.local
2. Click en "Graph"
3. Escribir consulta PromQL:

```promql
# CPU usage
rate(container_cpu_usage_seconds_total{namespace="backstage"}[5m])

# Memory usage
container_memory_usage_bytes{namespace="backstage"}

# Pod count
count(kube_pod_info{namespace="backstage"})
```

#### Ver Targets
1. http://prometheus.kind.local/targets
2. Revisar estado de todos los endpoints
3. Verde = Healthy, Rojo = Down

---

### Grafana

#### Crear Dashboard
1. Login en http://grafana.kind.local
2. Click "+" → "Dashboard"
3. "Add new panel"
4. Seleccionar Prometheus como data source
5. Escribir query PromQL
6. Configurar visualización
7. Save dashboard

#### Importar Dashboard
1. Click "+" → "Import"
2. Ingresar ID del dashboard (ej: 315 para Kubernetes)
3. Seleccionar Prometheus data source
4. Import

---

### ArgoCD

#### Crear Aplicación
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/myrepo
    targetRevision: HEAD
    path: k8s/
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

```bash
kubectl apply -f application.yaml
```

#### Sincronizar Aplicación
```bash
# Via CLI
argocd app sync my-app

# Via UI
# http://argocd.kind.local/applications/my-app
# Click "SYNC"
```

---

### Backstage

#### Navegar Catálogo
1. http://backstage.kind.local
2. Click "Catalog" en sidebar
3. Filtrar por:
   - Type: Component, System, API
   - Owner: platform-engineering
   - Tags: monitoring, gitops, etc.

#### Ver Páginas de Plataforma
- **Prometheus**: /prometheus
- **Grafana**: /grafana
- **ArgoCD**: /argocd
- **Kubernetes**: /kubernetes

---

## 🔧 Troubleshooting

### Problema: Pod no inicia

**Síntomas**: Pod en estado Pending/CrashLoopBackOff

**Diagnóstico**:
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous
```

**Soluciones Comunes**:
1. **ImagePullBackOff**: Verificar imagen existe
2. **ResourceQuota**: Aumentar quota
3. **ConfigMap/Secret**: Verificar existen
4. **PVC**: Verificar storage disponible

---

### Problema: Ingress no accesible

**Síntomas**: 404/502 al acceder a URL

**Diagnóstico**:
```bash
kubectl get ingress -n <namespace>
kubectl describe ingress <ingress-name> -n <namespace>
kubectl get svc -n <namespace>
```

**Soluciones**:
1. Verificar `/etc/hosts` tiene entrada
2. Verificar service existe y tiene endpoints
3. Verificar NGINX Ingress Controller corriendo
4. Verificar puerto está disponible

---

### Problema: Prometheus no scraping

**Síntomas**: Targets en estado DOWN

**Diagnóstico**:
```bash
# Ver targets
curl -s http://prometheus.kind.local/api/v1/targets | jq

# Ver configuración
kubectl get configmap -n monitoring prometheus-prometheus -o yaml
```

**Soluciones**:
1. Verificar ServiceMonitor existe
2. Verificar labels coinciden
3. Verificar network policies
4. Verificar métricas endpoint accesible

---

## 📊 Diagramas

### Arquitectura de Red

```
Internet/Browser
      │
      ▼
┌──────────────┐
│  localhost   │
│  127.0.0.1   │
└──────────────┘
      │
      ▼
┌─────────────────────────────────────┐
│      Kind Docker Container          │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  NGINX Ingress (Port 80/443) │  │
│  └──────────────────────────────┘  │
│           │                         │
│           ▼                         │
│  ┌──────────────────────────────┐  │
│  │  Kubernetes Services         │  │
│  │  (ClusterIP)                 │  │
│  └──────────────────────────────┘  │
│           │                         │
│           ▼                         │
│  ┌──────────────────────────────┐  │
│  │  Application Pods            │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

---

### Flujo de Observabilidad

```
┌─────────────┐
│ Application │
│    Pods     │
└─────────────┘
      │ :9090/metrics
      ▼
┌─────────────┐        ┌─────────────┐
│ Prometheus  │───────>│ AlertMgr    │──> Notifications
│   Scrape    │        │             │
└─────────────┘        └─────────────┘
      │
      │ Query API
      ▼
┌─────────────┐
│   Grafana   │
│  Dashboards │
└─────────────┘
      │
      ▼
   👤 User
```

---

### Flujo GitOps

```
┌──────────────┐
│  Git Repo    │
│  (Source)    │
└──────────────┘
      │
      │ Poll/Webhook
      ▼
┌──────────────┐
│   ArgoCD     │
│ Repo Server  │
└──────────────┘
      │
      │ Compare
      ▼
┌──────────────┐
│  Kubernetes  │
│   Cluster    │
└──────────────┘
      │
      │ Sync
      ▼
┌──────────────┐
│ Application  │
│   Running    │
└──────────────┘
```

---

## 📝 Notas Adicionales

### Resource Quotas

**Backstage Namespace**:
- CPU Limits: 3 cores
- CPU Requests: 1.5 cores
- Memory Limits: 6Gi
- Memory Requests: 2Gi
- Max Pods: 10

### Backup Recommendations

1. **Prometheus Data**: Configurar remote write
2. **Grafana Dashboards**: Export como JSON
3. **ArgoCD Apps**: Git es el backup
4. **Backstage Catalog**: PostgreSQL backup

### Security Best Practices

1. Cambiar passwords default
2. Habilitar RBAC en ArgoCD
3. TLS/HTTPS en producción
4. Network policies entre namespaces
5. Secret encryption at rest

---

## 🎯 Siguientes Pasos

1. ✅ Configurar alertas en Prometheus
2. ✅ Crear dashboards custom en Grafana
3. ✅ Automatizar deployments con ArgoCD
4. ✅ Agregar más servicios al catálogo Backstage
5. ✅ Configurar backup automatizado
6. ✅ Implementar logging con Loki
7. ✅ Agregar tracing con Tempo

---

**📧 Contacto**: platform-engineering@ba.com
**📖 Documentación**: http://backstage.kind.local/docs
**🐛 Issues**: GitHub Issues

---

*Última actualización: Octubre 6, 2025*
