# 📊 Implementación del Stack de Monitoreo - GitOps

**Fecha**: Octubre 11, 2025
**Proyecto**: Backstage Kind Migration with GitOps
**Maintainer**: Jaime Henao <jaime.andres.henao.arbelaez@ba.com>

---

## 🎯 Resumen

Este documento describe la implementación completa del stack de monitoreo para Backstage usando GitOps con ArgoCD.

## 📋 Stack Implementado

### Componentes Principales

- **kube-prometheus-stack** (Helm chart v65.0.0)
  - Prometheus Server con persistent storage (5Gi)
  - Grafana con GitHub OAuth
  - AlertManager
  - Prometheus Operator
  - Node Exporter
  - Kube State Metrics

### Configuraciones Personalizadas

- **9 Alertas** para Backstage y PostgreSQL (PrometheusRule)
- **Dashboard personalizado** de Backstage en Grafana
- **GitHub OAuth** para Grafana (integrado con ArgoCD)
- **Persistent storage** para todos los componentes

---

## 🏗️ Arquitectura GitOps

### Repositorio: `backstage-kind-migration`

```
backstage-kind-migration/
│
├── argocd/
│   ├── monitoring-application.yaml           # ArgoCD App para kube-prometheus-stack
│   └── monitoring-config-application.yaml    # ArgoCD App para configuraciones personalizadas
│
├── helm-charts/
│   └── monitoring/
│       ├── Chart.yaml                        # Metadata del Helm chart
│       ├── values.yaml                       # Configuración completa del stack
│       ├── README.md                         # Documentación técnica
│       └── templates/
│           ├── backstage-alerts.yaml         # PrometheusRule con 9 alertas
│           ├── backstage-dashboard.json      # Dashboard personalizado
│           └── backstage-dashboard-configmap.yaml
│
└── docs/
    ├── MONITORING_SETUP_GUIDE.md             # Guía de configuración
    ├── MONITORING_COMPLETE.md                # Estado completo del stack
    └── MONITORING_IMPLEMENTATION.md          # Este documento
```

### ArgoCD Applications

#### 1. `kube-prometheus-stack`

**Propósito**: Desplegar el stack principal de monitoreo

**Source**:
- Chart: `kube-prometheus-stack` desde https://prometheus-community.github.io/helm-charts
- Version: 65.0.0
- Values: `helm-charts/monitoring/values.yaml` desde el repo

**Configuración**:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kube-prometheus-stack
  namespace: argocd
spec:
  source:
    chart: kube-prometheus-stack
    repoURL: https://prometheus-community.github.io/helm-charts
    targetRevision: 65.0.0
    helm:
      valueFiles:
        - $values/helm-charts/monitoring/values.yaml
  sources:
    - chart: kube-prometheus-stack
      repoURL: https://prometheus-community.github.io/helm-charts
      targetRevision: 65.0.0
    - repoURL: https://github.com/Portfolio-jaime/backstage-kind-migration.git
      targetRevision: main
      ref: values
  destination:
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

#### 2. `backstage-monitoring-config`

**Propósito**: Desplegar alertas y dashboards personalizados

**Source**:
- Path: `helm-charts/monitoring`
- Repo: https://github.com/Portfolio-jaime/backstage-kind-migration.git
- Branch: main

**Recursos desplegados**:
- PrometheusRule: `backstage-alerts`
- ConfigMap: `backstage-grafana-dashboard`

---

## 🚀 Despliegue

### Prerequisitos

1. **Cluster Kind** funcionando
2. **ArgoCD** instalado y configurado
3. **GitHub OAuth App** configurado (mismo que ArgoCD)

### Paso 1: Crear Secret de GitHub OAuth (Solo primera vez)

```bash
kubectl create secret generic grafana-github-oauth -n monitoring \
  --from-literal=GF_AUTH_GITHUB_CLIENT_ID="Ov23liX98Qe1ectC1zdj" \
  --from-literal=GF_AUTH_GITHUB_CLIENT_SECRET="3133588a686087d188d1b85c145cfc562a4a9a69"
```

### Paso 2: Desplegar Stack Principal

```bash
kubectl apply -f argocd/monitoring-application.yaml
```

Esto desplegará:
- Prometheus Operator
- Prometheus Server (con 5Gi persistent storage)
- Grafana (con 2Gi persistent storage y GitHub OAuth)
- AlertManager (con 1Gi persistent storage)
- Node Exporter
- Kube State Metrics

**Tiempo de despliegue**: ~5-10 minutos

### Paso 3: Desplegar Configuraciones Personalizadas

```bash
kubectl apply -f argocd/monitoring-config-application.yaml
```

Esto desplegará:
- 9 alertas para Backstage (PrometheusRule)
- Dashboard personalizado de Backstage

**Tiempo de despliegue**: ~1 minuto

### Paso 4: Verificar Despliegue

```bash
# Ver aplicaciones en ArgoCD
kubectl get application -n argocd | grep monitoring

# Ver pods de monitoring
kubectl get pods -n monitoring

# Ver PVCs
kubectl get pvc -n monitoring

# Ver PrometheusRules
kubectl get prometheusrule -n monitoring

# Ver estado de sincronización
argocd app get kube-prometheus-stack
argocd app get backstage-monitoring-config
```

### Paso 5: Acceder a Servicios

**Opción 1: Ingress** (agregar a `/etc/hosts`):
```bash
echo "127.0.0.1 prometheus.kind.local grafana.kind.local alertmanager.kind.local" | sudo tee -a /etc/hosts
```

URLs:
- Prometheus: http://prometheus.kind.local
- Grafana: http://grafana.kind.local (Login con GitHub)
- AlertManager: http://alertmanager.kind.local

**Opción 2: Port Forward**:
```bash
# Prometheus
kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090

# Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# AlertManager
kubectl port-forward -n monitoring svc/prometheus-alertmanager 9093:9093
```

---

## ⚙️ Configuración

### Values.yaml Principal

Ubicación: `helm-charts/monitoring/values.yaml`

**Highlights de configuración**:

```yaml
# Prometheus - Persistent storage
prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 5Gi

# Grafana - GitHub OAuth
grafana:
  grafana.ini:
    auth.github:
      enabled: true
      allowed_organizations: "Portfolio-jaime"

# Deshabilitar alertas de componentes que Kind no expone
defaultRules:
  rules:
    etcd: false
    kubeProxy: false
    kubeSchedulerAlerting: false
    kubeSchedulerRecording: false
```

### Alertas Configuradas

Archivo: `helm-charts/monitoring/templates/backstage-alerts.yaml`

| # | Alerta | Severidad | Descripción |
|---|--------|-----------|-------------|
| 1 | BackstagePodDown | Critical | Pod de Backstage no está Running por más de 5min |
| 2 | BackstagePodCrashLooping | Warning | Pod de Backstage reiniciando constantemente |
| 3 | BackstageHighMemoryUsage | Warning | Backstage usando > 85% de memoria por 10min |
| 4 | BackstageHighCPUUsage | Warning | Backstage usando > 85% de CPU por 10min |
| 5 | BackstagePodNotReady | Warning | Pod de Backstage not ready por más de 5min |
| 6 | PostgreSQLDown | Critical | PostgreSQL no está Running por más de 2min |
| 7 | PostgreSQLHighMemoryUsage | Warning | PostgreSQL usando > 90% de memoria por 10min |
| 8 | BackstageNamespaceQuotaExceeded | Warning | Namespace usando > 90% de quota |

**Verificar en Prometheus**: http://prometheus.kind.local/alerts

### Dashboard Personalizado

Archivo: `helm-charts/monitoring/templates/backstage-dashboard.json`

**Paneles incluidos**:
1. Pod CPU Usage (por pod)
2. Pod Memory Usage (por pod)
3. Pod Status
4. Pod Restarts
5. Network I/O (RX/TX)
6. Disk I/O (Read/Write)
7. PostgreSQL Connection Status

**Importar automáticamente**: El ConfigMap lo importa automáticamente en la carpeta "Backstage" de Grafana.

---

## 🔄 Actualizar Configuración

### Flujo GitOps

1. **Modificar configuración** localmente:
   ```bash
   # Editar values.yaml
   vim helm-charts/monitoring/values.yaml

   # O agregar nueva alerta
   vim helm-charts/monitoring/templates/backstage-alerts.yaml
   ```

2. **Commit y push**:
   ```bash
   git add helm-charts/monitoring/
   git commit -m "feat: actualizar configuración de monitoring"
   git push origin main
   ```

3. **ArgoCD sincroniza automáticamente** (por defecto cada 3 minutos)

4. **Forzar sincronización** (opcional):
   ```bash
   argocd app sync kube-prometheus-stack
   argocd app sync backstage-monitoring-config
   ```

### Ejemplos de Cambios Comunes

#### Aumentar Storage de Prometheus

```yaml
# En helm-charts/monitoring/values.yaml
prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 10Gi  # Cambiar de 5Gi a 10Gi
```

#### Agregar Nueva Alerta

```yaml
# En helm-charts/monitoring/templates/backstage-alerts.yaml
- alert: BackstageHighLatency
  expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{namespace="backstage"}[5m])) > 1
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Backstage high latency"
    description: "95th percentile latency is {{ $value }}s"
```

#### Cambiar Recursos de Prometheus

```yaml
# En helm-charts/monitoring/values.yaml
prometheus:
  prometheusSpec:
    resources:
      limits:
        cpu: 1000m      # Aumentar de 500m
        memory: 2Gi     # Aumentar de 1Gi
      requests:
        cpu: 500m       # Aumentar de 250m
        memory: 1Gi     # Aumentar de 512Mi
```

---

## 🚨 Targets DOWN en Kind (Comportamiento Normal)

### Targets Esperados DOWN

Los siguientes ServiceMonitors reportarán targets DOWN en Kind:

- ❌ `kube-controller-manager` (puerto 10257)
- ❌ `kube-scheduler` (puerto 10259)
- ❌ `kube-proxy` (puerto 10249)
- ❌ `etcd` (puerto 2381)

### ¿Por qué?

Kind (Kubernetes in Docker) **no expone estos puertos por seguridad y simplicidad**. Estos componentes internos del control plane se ejecutan dentro del contenedor de Kind pero no están accesibles externamente.

### ¿Es un problema?

**NO**. Para monitorear aplicaciones y workloads tienes todos los targets necesarios:

- ✅ Kubelet
- ✅ API Server
- ✅ Node Exporter
- ✅ Kube State Metrics
- ✅ CoreDNS

### Solución Aplicada

En `values.yaml` se deshabilitaron las alertas para estos componentes:

```yaml
defaultRules:
  rules:
    etcd: false
    kubeProxy: false
    kubeSchedulerAlerting: false
    kubeSchedulerRecording: false
```

---

## 🛠️ Troubleshooting

### ArgoCD no sincroniza cambios

**Síntomas**: Cambios en el repo no se reflejan en el cluster

**Soluciones**:
```bash
# 1. Verificar estado de la app
argocd app get kube-prometheus-stack

# 2. Ver diff de cambios
argocd app diff kube-prometheus-stack

# 3. Forzar refresh
argocd app get kube-prometheus-stack --refresh

# 4. Forzar sincronización
argocd app sync kube-prometheus-stack --force

# 5. Ver logs de ArgoCD
kubectl logs -n argocd deployment/argocd-application-controller -f
```

### Prometheus no scrapeando Backstage

**Síntomas**: Target `backstage` DOWN o no aparece

**Verificar**:
```bash
# 1. Verificar ServiceMonitor
kubectl get servicemonitor backstage -n backstage

# 2. Verificar endpoint de métricas
kubectl run test --rm -it --image=curlimages/curl -- \
  curl http://backstage.backstage:7007/metrics

# 3. Ver configuración de Prometheus
kubectl get prometheus prometheus-prometheus -n monitoring -o yaml | grep -A 20 additionalScrapeConfigs

# 4. Ver logs de Prometheus
kubectl logs -n monitoring prometheus-prometheus-prometheus-0 -c prometheus | grep backstage
```

### Grafana no muestra dashboard

**Síntomas**: Dashboard de Backstage no aparece en Grafana

**Verificar**:
```bash
# 1. Verificar ConfigMap
kubectl get configmap backstage-grafana-dashboard -n monitoring

# 2. Ver configuración de Grafana
kubectl get configmap kube-prometheus-stack-grafana -n monitoring -o yaml | grep -A 10 dashboardProviders

# 3. Reiniciar Grafana
kubectl rollout restart deployment kube-prometheus-stack-grafana -n monitoring

# 4. Ver logs de Grafana
kubectl logs -n monitoring deployment/kube-prometheus-stack-grafana -f
```

### PVC pendiente

**Síntomas**: PVC en estado `Pending`

**Verificar**:
```bash
# 1. Ver detalles del PVC
kubectl describe pvc <pvc-name> -n monitoring

# 2. Verificar StorageClass
kubectl get storageclass

# 3. Ver eventos
kubectl get events -n monitoring --sort-by='.lastTimestamp'

# 4. Para Kind, debe usar storageClass: standard
```

---

## 📊 Estado Actual

### Recursos Desplegados

```bash
$ kubectl get all -n monitoring

NAME                                                         READY   STATUS    RESTARTS
pod/alertmanager-prometheus-alertmanager-0                   2/2     Running   0
pod/kube-prometheus-stack-grafana-xxxxx                      3/3     Running   0
pod/kube-prometheus-stack-kube-state-metrics-xxxxx           1/1     Running   0
pod/kube-prometheus-stack-prometheus-node-exporter-xxxxx     1/1     Running   0
pod/prometheus-operator-xxxxx                                1/1     Running   0
pod/prometheus-prometheus-prometheus-0                       2/2     Running   0
```

### Persistent Volumes

```bash
$ kubectl get pvc -n monitoring

NAME                                                              STATUS   VOLUME    CAPACITY
alertmanager-prometheus-alertmanager-db-...-0                     Bound    pvc-...   1Gi
kube-prometheus-stack-grafana                                     Bound    pvc-...   2Gi
prometheus-prometheus-prometheus-db-...-0                         Bound    pvc-...   5Gi
```

### ArgoCD Applications

```bash
$ kubectl get application -n argocd | grep monitoring

kube-prometheus-stack         Synced        Healthy
backstage-monitoring-config   Synced        Healthy
```

---

## 📚 Referencias

- [Documentación técnica del Helm chart](../helm-charts/monitoring/README.md)
- [Guía de configuración](MONITORING_SETUP_GUIDE.md)
- [Estado completo del stack](MONITORING_COMPLETE.md)
- [kube-prometheus-stack Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)

---

## 🎯 Próximos Pasos

### Corto Plazo

1. **Habilitar métricas de Backstage**
   - Instalar plugin `@backstage/plugin-prometheus`
   - Configurar endpoint `/metrics`
   - Crear ServiceMonitor

2. **Configurar notificaciones**
   - Slack para alertas warning
   - Email para alertas critical

### Mediano Plazo

3. **Dashboards adicionales**
   - Dashboard de PostgreSQL
   - Dashboard de ArgoCD
   - Dashboard de namespace completo

4. **Logs centralizados**
   - Instalar Loki
   - Configurar Promtail
   - Integrar con Grafana

### Largo Plazo

5. **Long-term storage**
   - Evaluar Thanos
   - Exportar métricas a S3/GCS

6. **Service Level Objectives (SLOs)**
   - Definir SLOs para Backstage
   - Configurar SLO dashboards
   - Alertas basadas en SLOs

---

**Última actualización**: Octubre 11, 2025
**Maintainer**: Jaime Henao <jaime.andres.henao.arbelaez@ba.com>
**Status**: ✅ Stack completamente desplegado y gestionado por GitOps
