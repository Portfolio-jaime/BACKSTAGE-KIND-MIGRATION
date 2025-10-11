# 📊 Backstage Monitoring Stack

Stack completo de monitoreo para Backstage usando `kube-prometheus-stack` + configuraciones personalizadas.

## 📋 Componentes

### Stack Principal (kube-prometheus-stack)

- **Prometheus** - Recolección y almacenamiento de métricas
- **Grafana** - Visualización de métricas y dashboards
- **AlertManager** - Gestión y enrutamiento de alertas
- **Prometheus Operator** - Gestión de Prometheus via CRDs
- **Node Exporter** - Métricas del sistema operativo
- **Kube State Metrics** - Métricas de recursos de Kubernetes

### Configuraciones Personalizadas

- **PrometheusRule**: `backstage-alerts.yaml` - 9 alertas para Backstage y PostgreSQL
- **ConfigMap**: Dashboard personalizado de Backstage para Grafana
- **GitHub OAuth** para Grafana (mismo OAuth app que ArgoCD)

## 🚀 Despliegue con ArgoCD

### Aplicación Principal: `kube-prometheus-stack`

```bash
kubectl apply -f argocd/monitoring-application.yaml
```

Esta aplicación:
- Despliega el Helm chart oficial de `kube-prometheus-stack`
- Usa `values.yaml` desde este repositorio (`helm-charts/monitoring/values.yaml`)
- Configuración automática de persistent storage (5Gi para Prometheus, 2Gi para Grafana)

### Aplicación de Configuraciones: `backstage-monitoring-config`

```bash
kubectl apply -f argocd/monitoring-config-application.yaml
```

Esta aplicación:
- Despliega alertas personalizadas (PrometheusRule)
- Despliega dashboard personalizado (ConfigMap)
- Gestiona configuraciones adicionales

## 📁 Estructura de Archivos

```
helm-charts/monitoring/
├── Chart.yaml                              # Metadata del Helm chart
├── values.yaml                             # Configuración completa del stack
├── README.md                               # Esta documentación
└── templates/
    ├── backstage-alerts.yaml               # 9 alertas para Backstage
    ├── backstage-dashboard.json            # Dashboard personalizado
    └── backstage-dashboard-configmap.yaml  # ConfigMap para importar dashboard
```

## ⚙️ Configuración

### Persistent Storage

**Prometheus**: 5Gi (gestionado automáticamente por Operator)
```yaml
storageSpec:
  volumeClaimTemplate:
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 5Gi
```

**Grafana**: 2Gi
```yaml
persistence:
  enabled: true
  size: 2Gi
```

**AlertManager**: 1Gi
```yaml
storage:
  volumeClaimTemplate:
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 1Gi
```

### GitHub OAuth para Grafana

Configurado para usar el mismo OAuth App que ArgoCD:

```yaml
auth.github:
  enabled: true
  allowed_organizations: "Portfolio-jaime"
  role_attribute_path: "contains(groups[*], 'Portfolio-jaime') && 'Admin' || 'Viewer'"
```

**Secrets requerido:**
```bash
kubectl create secret generic grafana-github-oauth -n monitoring \
  --from-literal=GF_AUTH_GITHUB_CLIENT_ID="Ov23liX98Qe1ectC1zdj" \
  --from-literal=GF_AUTH_GITHUB_CLIENT_SECRET="your-secret-here"
```

### Alertas Configuradas

| Alerta | Severidad | Condición | For |
|--------|-----------|-----------|-----|
| BackstagePodDown | Critical | Pod no está Running | 5m |
| BackstagePodCrashLooping | Warning | Rate de restarts > 0 | 5m |
| BackstageHighMemoryUsage | Warning | Memoria > 85% | 10m |
| BackstageHighCPUUsage | Warning | CPU > 85% | 10m |
| BackstagePodNotReady | Warning | Pod not ready | 5m |
| PostgreSQLDown | Critical | PostgreSQL no Running | 2m |
| PostgreSQLHighMemoryUsage | Warning | PostgreSQL memoria > 90% | 10m |
| BackstageNamespaceQuotaExceeded | Warning | Namespace quota > 90% | 5m |

### Targets DOWN en Kind (Normal)

Los siguientes targets estarán DOWN en Kind y es **comportamiento normal**:

- ❌ kube-controller-manager (puerto 10257)
- ❌ kube-scheduler (puerto 10259)
- ❌ kube-proxy (puerto 10249)
- ❌ etcd (puerto 2381)

**Razón**: Kind no expone estos puertos por seguridad y simplicidad.

**Solución aplicada**: Alertas deshabilitadas en `values.yaml`:
```yaml
defaultRules:
  rules:
    etcd: false
    kubeProxy: false
    kubeSchedulerAlerting: false
    kubeSchedulerRecording: false
```

## 🔗 Acceso a Servicios

| Servicio | URL | Port Forward | Credenciales |
|----------|-----|--------------|--------------|
| **Prometheus** | http://prometheus.kind.local | `kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090` | N/A |
| **Grafana** | http://grafana.kind.local | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80` | GitHub OAuth o admin/admin123 |
| **AlertManager** | http://alertmanager.kind.local | `kubectl port-forward -n monitoring svc/prometheus-alertmanager 9093:9093` | N/A |

**Agregar a `/etc/hosts`:**
```bash
echo "127.0.0.1 prometheus.kind.local grafana.kind.local alertmanager.kind.local" | sudo tee -a /etc/hosts
```

## 🔄 Actualizar Configuración

### Modificar values.yaml

1. Edita `helm-charts/monitoring/values.yaml`
2. Commit y push a GitHub
3. ArgoCD sincronizará automáticamente

```bash
git add helm-charts/monitoring/values.yaml
git commit -m "feat: actualizar configuración de monitoring"
git push origin main
```

### Agregar Nueva Alerta

1. Edita `helm-charts/monitoring/templates/backstage-alerts.yaml`
2. Agrega nueva regla en `spec.groups[0].rules`
3. Commit y push
4. ArgoCD aplicará automáticamente

### Agregar Nuevo Dashboard

1. Exporta dashboard desde Grafana UI como JSON
2. Guarda en `helm-charts/monitoring/templates/`
3. Crea ConfigMap en templates
4. Commit y push

## 🛠️ Comandos Útiles

### Ver Estado del Stack

```bash
# Pods de monitoring
kubectl get pods -n monitoring

# Aplicaciones de ArgoCD
kubectl get application -n argocd | grep monitoring

# PVCs
kubectl get pvc -n monitoring

# PrometheusRules
kubectl get prometheusrule -n monitoring

# ServiceMonitors
kubectl get servicemonitor -A
```

### Forzar Sincronización

```bash
# Sincronizar stack principal
argocd app sync kube-prometheus-stack

# Sincronizar configuraciones
argocd app sync backstage-monitoring-config
```

### Ver Logs

```bash
# Prometheus
kubectl logs -n monitoring prometheus-prometheus-prometheus-0 -c prometheus -f

# Grafana
kubectl logs -n monitoring deployment/kube-prometheus-stack-grafana -f

# AlertManager
kubectl logs -n monitoring alertmanager-prometheus-alertmanager-0 -c alertmanager -f
```

## 📚 Referencias

- [kube-prometheus-stack Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [Grafana Documentation](https://grafana.com/docs/)
- [PrometheusRule CRD](https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.PrometheusRule)

---

**Maintainer**: Jaime Henao <jaime.andres.henao.arbelaez@ba.com>
**Última actualización**: Octubre 11, 2025
