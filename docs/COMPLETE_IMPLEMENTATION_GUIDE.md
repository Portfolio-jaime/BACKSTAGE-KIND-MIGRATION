# 📚 Guía Completa de Implementación - Platform Monitoring Stack

**Fecha**: Octubre 6, 2025
**Proyecto**: Backstage Platform on Kind
**Autor**: Platform Engineering Team

---

## 📑 Índice

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Arquitectura Implementada](#arquitectura-implementada)
3. [Componentes Desplegados](#componentes-desplegados)
4. [Pasos de Implementación](#pasos-de-implementación)
5. [Configuración de Backstage Pages](#configuración-de-backstage-pages)
6. [Catálogo de Servicios](#catálogo-de-servicios)
7. [Acceso y Credenciales](#acceso-y-credenciales)
8. [Troubleshooting](#troubleshooting)
9. [Anexos](#anexos)

---

## 📊 Resumen Ejecutivo

### ✅ Objetivo Cumplido

Se implementó exitosamente un **Developer Portal completo** con:
- ✅ Backstage como portal central
- ✅ Stack de monitoring (Prometheus + Grafana)
- ✅ GitOps con ArgoCD
- ✅ Gestión de alertas (AlertManager)
- ✅ Catálogo unificado de servicios
- ✅ Documentación exhaustiva

### 🎯 Resultados

| Componente | Estado | URL | Namespace |
|------------|--------|-----|-----------|
| Backstage | ✅ Running | http://backstage.kind.local | backstage |
| Prometheus | ✅ Running | http://prometheus.kind.local | monitoring |
| Grafana | ✅ Running | http://grafana.kind.local | monitoring |
| ArgoCD | ✅ Running | http://argocd.kind.local | argocd |
| AlertManager | ✅ Running | http://alertmanager.kind.local | monitoring |

---

## 🏗️ Arquitectura Implementada

### Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                    Usuario / Desarrollador                   │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      /etc/hosts (DNS Local)                  │
│  127.0.0.1 backstage.kind.local                             │
│  127.0.0.1 prometheus.kind.local                            │
│  127.0.0.1 grafana.kind.local                               │
│  127.0.0.1 argocd.kind.local                                │
│  127.0.0.1 alertmanager.kind.local                          │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              NGINX Ingress Controller (Port 80)              │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┐  │
│  │Backstage │Prometheus│ Grafana  │ ArgoCD   │AlertMgr  │  │
│  │ Ingress  │ Ingress  │ Ingress  │ Ingress  │ Ingress  │  │
│  └──────────┴──────────┴──────────┴──────────┴──────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         ▼                  ▼                  ▼
┌─────────────────┐ ┌──────────────┐ ┌──────────────┐
│   Backstage NS  │ │ Monitoring NS│ │  ArgoCD NS   │
│                 │ │              │ │              │
│ ┌─────────────┐ │ │┌───────────┐│ │┌───────────┐ │
│ │ Backstage   │ │ ││Prometheus ││ ││ArgoCD Srv │ │
│ │ Deployment  │ │ ││StatefulSet││ ││Deployment │ │
│ │ (1 replica) │ │ │└───────────┘│ │└───────────┘ │
│ └─────────────┘ │ │┌───────────┐│ │┌───────────┐ │
│ ┌─────────────┐ │ ││ Grafana   ││ ││Repo Server│ │
│ │ PostgreSQL  │ │ ││Deployment ││ ││Deployment │ │
│ │ StatefulSet │ │ │└───────────┘│ │└───────────┘ │
│ └─────────────┘ │ │┌───────────┐│ │┌───────────┐ │
│ ┌─────────────┐ │ ││AlertMgr   ││ ││App Ctrl   │ │
│ │ ConfigMap   │ │ ││StatefulSet││ ││StatefulSet│ │
│ │ Secrets     │ │ │└───────────┘│ │└───────────┘ │
│ │ RBAC        │ │ │              │ │              │
│ └─────────────┘ │ │              │ │              │
└─────────────────┘ └──────────────┘ └──────────────┘
         │                  │                  │
         └──────────────────┴──────────────────┘
                            ▼
         ┌────────────────────────────────────┐
         │   Kind Kubernetes Cluster          │
         │   • 1 Control Plane Node           │
         │   • Docker Desktop Backend         │
         └────────────────────────────────────┘
```

### Flujo de Datos

```
┌──────────────┐
│ Applications │
│    Pods      │
└──────┬───────┘
       │ Expose /metrics
       ▼
┌──────────────┐      ┌──────────────┐
│  Prometheus  │─────>│ AlertManager │──> Notifications
│   Scrape     │      │  (Alerts)    │
└──────┬───────┘      └──────────────┘
       │
       │ Query API (PromQL)
       ▼
┌──────────────┐
│   Grafana    │
│  Dashboards  │
└──────┬───────┘
       │
       ▼
   👤 User

┌──────────────┐
│  Git Repo    │
│  (Source)    │
└──────┬───────┘
       │ Sync
       ▼
┌──────────────┐
│   ArgoCD     │
│ Repo Server  │
└──────┬───────┘
       │ Deploy
       ▼
┌──────────────┐
│  Kubernetes  │
│   Cluster    │
└──────────────┘

┌──────────────┐
│  Backstage   │
│   Portal     │
└──────┬───────┘
       │
       ├──> Catalog (Components)
       ├──> TechDocs
       ├──> Software Templates
       └──> External Links (to all services)
```

---

## 🧩 Componentes Desplegados

### 1. Backstage (Namespace: `backstage`)

#### Deployment
```yaml
Name: backstage
Replicas: 1 (laboratorio)
Image: jaimehenao8126/backstage-production:latest
Resources:
  Requests: 250m CPU, 512Mi RAM
  Limits: 1 CPU, 2Gi RAM
Ports: 7007 (http)
```

#### PostgreSQL
```yaml
Name: psql-postgresql
Type: StatefulSet
Replicas: 1
Image: postgresql:14
Port: 5432
Database: backstage
User: backstage
```

#### ConfigMaps
- `backstage-env-config`: Variables de entorno
- `backstage-enhanced-config`: Configuración completa de Backstage
- `backstage-platform-catalog`: Catálogo de servicios de plataforma

#### Secrets
- `backstage-secrets`: Credenciales (GitHub, ArgoCD, PostgreSQL)
- `psql-postgresql`: Password de PostgreSQL

#### RBAC
- ServiceAccount: `backstage`
- ClusterRole: `backstage-read` (lectura de recursos K8s)
- ClusterRoleBinding: `backstage-read-binding`

#### Services
- `backstage`: ClusterIP en puerto 80

#### Ingress
- Host: `backstage.kind.local`
- Backend: `backstage:80`

---

### 2. Monitoring Stack (Namespace: `monitoring`)

#### Prometheus
```yaml
Name: prometheus-prometheus
Type: StatefulSet
Replicas: 1
Image: quay.io/prometheus/prometheus
Port: 9090
Storage: PVC
Retention: 15 days
```

**Configuración**:
- Scrape interval: 30s
- Service discovery: Kubernetes
- Alert rules: Configured
- Remote write: Disabled (local)

#### Grafana
```yaml
Name: kube-prometheus-stack-grafana
Type: Deployment
Replicas: 1
Image: grafana/grafana
Port: 80
```

**Data Sources**:
- Prometheus (default)
- Kubernetes API

**Plugins Instalados**:
- Kubernetes
- Prometheus
- Pie Chart
- State Timeline

#### AlertManager
```yaml
Name: alertmanager-prometheus-alertmanager
Type: StatefulSet
Replicas: 1
Image: quay.io/prometheus/alertmanager
Port: 9093
```

#### Node Exporter
```yaml
Name: kube-prometheus-stack-prometheus-node-exporter
Type: DaemonSet
Image: quay.io/prometheus/node-exporter
Port: 9100
```

#### Kube State Metrics
```yaml
Name: kube-prometheus-stack-kube-state-metrics
Type: Deployment
Replicas: 1
Port: 8080
```

#### Ingresses
- `prometheus`: prometheus.kind.local → prometheus-prometheus:9090
- `grafana`: grafana.kind.local → kube-prometheus-stack-grafana:80
- `alertmanager`: alertmanager.kind.local → prometheus-alertmanager:9093

---

### 3. ArgoCD (Namespace: `argocd`)

#### ArgoCD Server
```yaml
Name: argocd-server
Type: Deployment
Replicas: 1
Ports: 8080 (http), 8083 (https)
```

#### Repo Server
```yaml
Name: argocd-repo-server
Type: Deployment
Replicas: 1
Port: 8081
```

#### Application Controller
```yaml
Name: argocd-application-controller
Type: StatefulSet
Replicas: 1
```

#### Redis
```yaml
Name: argocd-redis
Type: Deployment
Replicas: 1
Port: 6379
```

#### Dex (SSO)
```yaml
Name: argocd-dex-server
Type: Deployment
Replicas: 1
Ports: 5556, 5557
```

#### Ingress
- Host: `argocd.kind.local`
- Backend: `argocd-server:443`
- Protocol: HTTPS (backend)

---

## 🚀 Pasos de Implementación

### Fase 1: Preparación del Cluster

#### 1.1 Crear Cluster Kind
```bash
kind create cluster --name kind

# Verificar
kubectl cluster-info
kubectl get nodes
```

#### 1.2 Instalar NGINX Ingress
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Esperar a que esté listo
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

---

### Fase 2: Desplegar Monitoring Stack

#### 2.1 Agregar Helm Repository
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

#### 2.2 Instalar Kube-Prometheus-Stack
```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
  --set grafana.adminPassword=admin
```

#### 2.3 Verificar Instalación
```bash
kubectl get pods -n monitoring
kubectl get svc -n monitoring
kubectl get statefulset -n monitoring
```

#### 2.4 Crear Ingresses
```bash
kubectl apply -f kubernetes/monitoring-ingresses.yaml

# Verificar
kubectl get ingress -n monitoring
```

**Archivo**: `kubernetes/monitoring-ingresses.yaml`
```yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus
  namespace: monitoring
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: prometheus.kind.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-prometheus
            port:
              number: 9090
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
  namespace: monitoring
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: grafana.kind.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kube-prometheus-stack-grafana
            port:
              number: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: alertmanager
  namespace: monitoring
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: alertmanager.kind.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-alertmanager
            port:
              number: 9093
```

---

### Fase 3: Desplegar ArgoCD

#### 3.1 Crear Namespace
```bash
kubectl create namespace argocd
```

#### 3.2 Instalar ArgoCD
```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

#### 3.3 Esperar a que esté listo
```bash
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-server -n argocd
```

#### 3.4 Crear Ingress
```bash
kubectl apply -f kubernetes/argocd-ingress.yaml
```

**Archivo**: `kubernetes/argocd-ingress.yaml`
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  ingressClassName: nginx
  rules:
  - host: argocd.kind.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 443
```

#### 3.5 Obtener Password Inicial
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

---

### Fase 4: Desplegar Backstage

#### 4.1 Crear Namespace
```bash
kubectl apply -f kubernetes/namespace.yaml
```

**Archivo**: `kubernetes/namespace.yaml`
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: backstage
  labels:
    name: backstage
```

#### 4.2 Crear Secrets
```bash
kubectl apply -f kubernetes/secrets.yaml
```

**Archivo**: `kubernetes/secrets.yaml`
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: backstage-secrets
  namespace: backstage
type: Opaque
stringData:
  # PostgreSQL
  POSTGRES_HOST: "psql-postgresql.backstage.svc.cluster.local"
  POSTGRES_PORT: "5432"
  POSTGRES_USER: "backstage"
  POSTGRES_PASSWORD: "backstage"
  POSTGRES_DB: "backstage"

  # GitHub
  GITHUB_TOKEN: "tu-token-aqui"
  AUTH_GITHUB_CLIENT_ID: "tu-client-id"
  AUTH_GITHUB_CLIENT_SECRET: "tu-client-secret"

  # ArgoCD
  ARGOCD_USERNAME: "admin"
  ARGOCD_PASSWORD: "password-argocd"
  ARGOCD_AUTH_TOKEN: "token-argocd"

  # Backend
  BACKEND_SECRET: "random-secret-key"
```

#### 4.3 Crear ConfigMap
```bash
kubectl apply -f kubernetes/configmap.yaml
```

**Archivo**: `kubernetes/configmap.yaml`
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backstage-env-config
  namespace: backstage
data:
  POSTGRES_HOST: "psql-postgresql.backstage.svc.cluster.local"
  POSTGRES_PORT: "5432"
  POSTGRES_DB: "backstage"
  NODE_ENV: "production"
  LOG_LEVEL: "info"
  APP_BASE_URL: "http://backstage.kind.local"
  BACKEND_BASE_URL: "http://backstage.kind.local"
  CORS_ORIGIN: "http://backstage.kind.local"
```

#### 4.4 Crear RBAC
```bash
kubectl apply -f kubernetes/rbac.yaml
```

**Archivo**: `kubernetes/rbac.yaml`
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backstage
  namespace: backstage
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: backstage-read
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "configmaps", "namespaces"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["deployments", "replicasets", "statefulsets"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: backstage-read-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: backstage-read
subjects:
  - kind: ServiceAccount
    name: backstage
    namespace: backstage
```

#### 4.5 Desplegar PostgreSQL (gestionado por ArgoCD)

PostgreSQL ahora se despliega y gestiona a través de ArgoCD, utilizando el chart de Helm local ubicado en `helm-charts/postgresql` en este repositorio. Las credenciales se obtienen del secret `backstage-secrets`.

**No es necesario ejecutar comandos `helm install` directamente para PostgreSQL.** La sincronización la realiza ArgoCD automáticamente al detectar los cambios en el repositorio.

#### 4.6 Crear Deployment
```bash
kubectl apply -f kubernetes/simple-deployment.yaml
```

**Archivo**: `kubernetes/simple-deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backstage
  namespace: backstage
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backstage
  template:
    metadata:
      labels:
        app: backstage
    spec:
      serviceAccountName: backstage
      containers:
      - name: backstage
        image: jaimehenao8126/backstage-production:latest
        imagePullPolicy: IfNotPresent
        ports:
        - name: http
          containerPort: 7007
        env:
        - name: APP_CONFIG_app_baseUrl
          value: "http://backstage.kind.local"
        - name: APP_CONFIG_backend_baseUrl
          value: "http://backstage.kind.local"
        envFrom:
        - secretRef:
            name: backstage-secrets
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
        volumeMounts:
        - name: app-config
          mountPath: /app/app-config.production.yaml
          subPath: app-config.yaml
        - name: users
          mountPath: /app/users.yaml
          subPath: users.yaml
        - name: platform-services
          mountPath: /app/catalog/platform-services.yaml
          subPath: platform-services.yaml
      volumes:
      - name: app-config
        configMap:
          name: backstage-enhanced-config
      - name: users
        configMap:
          name: backstage-enhanced-config
      - name: platform-services
        configMap:
          name: backstage-platform-catalog
```

#### 4.7 Crear Service
```bash
kubectl apply -f kubernetes/service.yaml
```

**Archivo**: `kubernetes/service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: backstage
  namespace: backstage
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 7007
    protocol: TCP
    name: http
  selector:
    app: backstage
```

#### 4.8 Crear Ingress
```bash
kubectl apply -f kubernetes/ingress.yaml
```

**Archivo**: `kubernetes/ingress.yaml`
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: backstage
  namespace: backstage
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: backstage.kind.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: backstage
            port:
              number: 80
```

---

### Fase 5: Configurar DNS Local

#### 5.1 Editar /etc/hosts

**macOS/Linux**:
```bash
sudo nano /etc/hosts
```

**Windows**:
```
Notepad como Administrator
C:\Windows\System32\drivers\etc\hosts
```

#### 5.2 Agregar Entradas
```
127.0.0.1 backstage.kind.local
127.0.0.1 prometheus.kind.local
127.0.0.1 grafana.kind.local
127.0.0.1 argocd.kind.local
127.0.0.1 alertmanager.kind.local
```

---

### Fase 6: Configurar Catálogo de Backstage

#### 6.1 Crear Catálogo de Platform Services
```bash
kubectl create configmap backstage-platform-catalog \
  -n backstage \
  --from-file=platform-services.yaml=backstage-catalog/platform-services.yaml
```

**Archivo**: `backstage-catalog/platform-services.yaml`
```yaml
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: prometheus
  title: Prometheus Monitoring
  description: Monitoring and alerting toolkit
  annotations:
    backstage.io/kubernetes-id: prometheus
    backstage.io/kubernetes-namespace: monitoring
  tags:
    - monitoring
    - prometheus
    - metrics
  links:
    - url: http://prometheus.kind.local
      title: Prometheus UI
      icon: dashboard
    - url: http://prometheus.kind.local/targets
      title: Targets
      icon: catalog
    - url: http://prometheus.kind.local/alerts
      title: Alerts
      icon: alert
spec:
  type: service
  lifecycle: production
  owner: platform-engineering
  system: monitoring
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: grafana
  title: Grafana Dashboards
  description: Analytics and visualization platform
  annotations:
    backstage.io/kubernetes-id: grafana
    backstage.io/kubernetes-namespace: monitoring
  tags:
    - monitoring
    - grafana
    - visualization
  links:
    - url: http://grafana.kind.local
      title: Grafana UI
      icon: dashboard
    - url: http://grafana.kind.local/dashboards
      title: Dashboards
      icon: catalog
spec:
  type: service
  lifecycle: production
  owner: platform-engineering
  system: monitoring
---
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: argocd
  title: ArgoCD GitOps
  description: Declarative GitOps CD tool
  annotations:
    backstage.io/kubernetes-id: argocd-server
    backstage.io/kubernetes-namespace: argocd
  tags:
    - gitops
    - argocd
    - deployment
  links:
    - url: http://argocd.kind.local
      title: ArgoCD Console
      icon: dashboard
    - url: http://argocd.kind.local/applications
      title: Applications
      icon: catalog
spec:
  type: service
  lifecycle: production
  owner: platform-engineering
  system: platform
---
apiVersion: backstage.io/v1alpha1
kind: System
metadata:
  name: monitoring
  title: Monitoring System
  description: Complete monitoring stack
spec:
  owner: platform-engineering
---
apiVersion: backstage.io/v1alpha1
kind: System
metadata:
  name: platform
  title: Platform Services
  description: Core platform services
spec:
  owner: platform-engineering
```

#### 6.2 Actualizar ConfigMap de Backstage

Agregar la ubicación del catálogo en `backstage-enhanced-config`:

```yaml
catalog:
  locations:
    - type: file
      target: /app/catalog/platform-services.yaml
```

#### 6.3 Reiniciar Backstage
```bash
kubectl delete pod -n backstage -l app=backstage
```

---

## 🎨 Configuración de Backstage Pages

### Problema: Pages No Aparecen en Backstage

Las pages YAML que creamos son **templates de documentación**, no páginas funcionales de Backstage.

Para que aparezcan páginas custom en Backstage, necesitas:

### Solución 1: Usar Links en el Catálogo ✅ (Implementado)

Los componentes del catálogo tienen links directos a cada servicio:

**Acceso**:
1. Ir a http://backstage.kind.local
2. Click en **"Catalog"**
3. Buscar componentes: `prometheus`, `grafana`, `argocd`
4. Click en cada componente
5. En la pestaña **"Overview"** ver los links

### Solución 2: Crear Custom Pages (Requiere Código)

Para crear páginas custom verdaderas necesitas:

#### 2.1 Modificar el código fuente de Backstage

**Archivo**: `packages/app/src/App.tsx`
```tsx
import { MonitoringPage } from './components/monitoring';

const routes = (
  <FlatRoutes>
    {/* ... otras rutas ... */}
    <Route path="/monitoring" element={<MonitoringPage />} />
  </FlatRoutes>
);
```

#### 2.2 Crear componente de página

**Archivo**: `packages/app/src/components/monitoring/MonitoringPage.tsx`
```tsx
import React from 'react';
import { Page, Header, Content } from '@backstage/core-components';

export const MonitoringPage = () => {
  return (
    <Page themeId="tool">
      <Header title="Platform Monitoring" />
      <Content>
        <iframe
          src="http://prometheus.kind.local"
          width="100%"
          height="800px"
        />
      </Content>
    </Page>
  );
};
```

#### 2.3 Agregar al sidebar

**Archivo**: `packages/app/src/components/Root/Root.tsx`
```tsx
<SidebarItem icon={MonitoringIcon} to="monitoring" text="Monitoring" />
```

#### 2.4 Rebuild y redeploy
```bash
yarn build
docker build -t backstage-custom .
kind load docker-image backstage-custom
kubectl set image deployment/backstage backstage=backstage-custom -n backstage
```

### Solución 3: Usar Dashboard Externo ✅ (Recomendado para Laboratorio)

La forma más simple es usar el dashboard que ya creamos:

**Archivo creado**: `templates/ba-platform-monitoring/config.yaml`

Este dashboard incluye:
- Links a todos los servicios
- Iframes embebidos
- Quick actions
- Documentación

**Para usarlo**:
1. Los links ya están en el catálogo de cada componente
2. Acceder directamente a las URLs:
   - http://prometheus.kind.local
   - http://grafana.kind.local
   - http://argocd.kind.local

---

## 📋 Catálogo de Servicios

### Componentes en el Catálogo

| Nombre | Tipo | Sistema | Owner | Links |
|--------|------|---------|-------|-------|
| prometheus | service | monitoring | platform-engineering | UI, Targets, Alerts |
| grafana | service | monitoring | platform-engineering | UI, Dashboards |
| argocd | service | platform | platform-engineering | Console, Apps |
| kind-kubernetes-cluster | service | platform | platform-engineering | Resources |
| alertmanager | service | monitoring | platform-engineering | UI, Alerts |

### Systems

- **monitoring**: Monitoring & Observability
- **platform**: Platform Services

### Cómo Navegar el Catálogo

1. **Ir a Backstage**: http://backstage.kind.local
2. **Click en "Catalog"** en el sidebar
3. **Filtrar por**:
   - Type: Component
   - Owner: platform-engineering
   - System: monitoring o platform
4. **Click en un componente** para ver detalles
5. **En la pestaña "Overview"** encontrarás los links a los servicios

---

## 🔑 Acceso y Credenciales

### Obtener Credenciales

#### Grafana
```bash
# Usuario: admin
# Password:
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d && echo
```

#### ArgoCD
```bash
# Usuario: admin
# Password:
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

#### PostgreSQL (Backstage)
```bash
# Usuario: backstage
# Password:
kubectl get secret -n backstage psql-postgresql \
  -o jsonpath="{.data.postgres-password}" | base64 -d && echo
```

---

## 🔧 Troubleshooting

### Comandos Útiles

```bash
# Ver todos los pods
kubectl get pods --all-namespaces

# Ver logs de Backstage
kubectl logs -f deployment/backstage -n backstage

# Reiniciar Backstage
kubectl rollout restart deployment/backstage -n backstage

# Ver eventos
kubectl get events -n backstage --sort-by='.lastTimestamp'

# Verificar ingresses
kubectl get ingress --all-namespaces

# Port-forward si ingress no funciona
kubectl port-forward svc/backstage 7007:80 -n backstage
kubectl port-forward svc/prometheus-prometheus 9090:9090 -n monitoring
kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring
```

### Problemas Comunes

#### Ingress 404/502
```bash
# Verificar /etc/hosts
cat /etc/hosts | grep kind.local

# Debe contener:
# 127.0.0.1 backstage.kind.local
# 127.0.0.1 prometheus.kind.local
# 127.0.0.1 grafana.kind.local
# 127.0.0.1 argocd.kind.local
# 127.0.0.1 alertmanager.kind.local
```

#### Pod no inicia
```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace>
```

#### Catálogo no carga componentes
```bash
# Verificar ConfigMap
kubectl get configmap backstage-platform-catalog -n backstage

# Verificar montaje en deployment
kubectl describe deployment backstage -n backstage | grep -A 5 "Mounts:"

# Reiniciar
kubectl delete pod -n backstage -l app=backstage
```

---

## 📚 Anexos

### Archivos Creados

#### Kubernetes Manifests
```
kubernetes/
├── namespace.yaml
├── secrets.yaml
├── configmap.yaml
├── rbac.yaml
├── simple-deployment.yaml
├── service.yaml
├── ingress.yaml
├── monitoring-ingresses.yaml
└── argocd-ingress.yaml
```

#### Helm Charts
```
helm-charts/
└── postgresql/
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
        ├── _helpers.tpl
        ├── deployment.yaml
        ├── pvc.yaml
        ├── secret.yaml
        └── service.yaml
```

#### Catalog
```
backstage-catalog/
└── platform-services.yaml
```

#### Dashboard Templates
```
backstage-dashboard-templates/
├── catalog/
│   └── platform-services.yaml
└── templates/
    ├── ba-platform-monitoring/
    │   ├── catalog-info.yaml
    │   └── config.yaml
    └── pages/
        ├── prometheus/page.yaml
        ├── grafana/page.yaml
        ├── argocd/page.yaml
        └── kubernetes/page.yaml
```

#### Documentation
```
docs/
├── PLATFORM_MONITORING_GUIDE.md
├── IMPLEMENTATION_SUMMARY.md
├── COMPLETE_IMPLEMENTATION_GUIDE.md (este archivo)
└── BACKSTAGE_PAGES_SETUP.md
```

---

## ✅ Checklist de Validación

- [x] Kind cluster funcionando
- [x] NGINX Ingress instalado
- [x] Prometheus desplegado y accesible
- [x] Grafana desplegado y accesible
- [x] ArgoCD desplegado y accesible
- [x] AlertManager desplegado y accesible
- [x] Backstage desplegado y accesible
- [x] PostgreSQL funcionando
- [x] Catálogo de servicios cargado
- [x] Ingresses configurados
- [x] DNS local configurado (/etc/hosts)
- [x] Resource quotas configurados
- [x] RBAC configurado
- [x] Documentación completa

---

## 🎯 Siguientes Pasos

### Para Acceder a las "Pages"

**Opción A - Usar Catálogo (Más Simple)** ✅
1. Ir a http://backstage.kind.local
2. Catalog → Buscar componente
3. Click en los links de Overview

**Opción B - URLs Directas** ✅
1. http://prometheus.kind.local
2. http://grafana.kind.local
3. http://argocd.kind.local

**Opción C - Crear Custom Pages (Requiere Desarrollo)**
1. Modificar código fuente de Backstage
2. Agregar rutas y componentes
3. Rebuild imagen
4. Redeploy

### Mejoras Futuras

- [ ] Implementar custom pages en código
- [ ] Configurar alertas en Prometheus
- [ ] Crear dashboards custom en Grafana
- [ ] Automatizar backups
- [ ] Implementar logging con Loki
- [ ] Agregar tracing con Tempo

---

**📧 Soporte**: platform-engineering@ba.com
**📖 Wiki**: http://backstage.kind.local/docs

---

*Última actualización: Octubre 6, 2025*
