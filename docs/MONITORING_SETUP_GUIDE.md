# 📊 Monitoring Setup Guide - Configuración Actualizada

**Fecha:** Octubre 11, 2025
**Proyecto:** Backstage Kind Migration
**Maintainer:** Jaime Henao <jaime.andres.henao.arbelaez@ba.com>

---

## ✅ Configuración Completada

### 1. **Dashboard Personalizado de Backstage** ✅

Dashboard creado con las siguientes métricas:
- CPU Usage por pod
- Memory Usage por pod
- Pod Status
- Pod Restarts
- Network I/O
- Disk I/O
- PostgreSQL Connection Status

**Importar dashboard:**
```bash
# En Grafana UI (http://grafana.kind.local):
# 1. Click "+" > Import
# 2. Upload monitoring/backstage-dashboard.json
# 3. Select Prometheus datasource
# 4. Import
```

### 2. **Alertas para Backstage** ✅

PrometheusRule configurado con 9 alertas:

| Alerta | Severidad | Condición |
|--------|-----------|-----------|
| BackstagePodDown | Critical | Pod no está Running por > 5min |
| BackstagePodCrashLooping | Warning | Restarts detectados |
| BackstageHighMemoryUsage | Warning | Memoria > 85% por 10min |
| BackstageHighCPUUsage | Warning | CPU > 85% por 10min |
| BackstagePodNotReady | Warning | Pod not ready > 5min |
| PostgreSQLDown | Critical | PostgreSQL down > 2min |
| PostgreSQLHighMemoryUsage | Warning | PostgreSQL memoria > 90% |
| BackstageNamespaceQuotaExceeded | Warning | Quota > 90% |

**Verificar alertas:**
```bash
kubectl get prometheusrule backstage-alerts -n monitoring

# Ver en Prometheus UI
# http://prometheus.kind.local/alerts
```

### 3. **Persistent Storage para Prometheus** ✅

Prometheus Operator gestiona automáticamente el almacenamiento persistente mediante volumeClaimTemplate:

```yaml
storage:
  volumeClaimTemplate:
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
      storageClassName: standard
```

**PVC creado automáticamente:**
```
prometheus-prometheus-prometheus-db-prometheus-prometheus-prometheus-0 - 5Gi Bound
```

**Beneficios:**
- ✅ Datos de métricas persisten al reiniciar pods
- ✅ Histórico de métricas disponible
- ✅ 5Gi de almacenamiento (configurable en Helm values)
- ✅ Gestionado automáticamente por el Operator

**Verificar:**
```bash
kubectl get pvc -n monitoring | grep prometheus
# prometheus-prometheus-prometheus-db-prometheus-prometheus-prometheus-0   Bound   5Gi

kubectl get prometheus prometheus-prometheus -n monitoring -o jsonpath='{.spec.storage}' | jq .
```

### 4. **Grafana OAuth con GitHub** ✅

Grafana configurado para login con GitHub:

**Configuración:**
- Client ID: Mismo OAuth App de ArgoCD
- Organization: Portfolio-jaime
- Admin role: Usuarios de la org tienen rol Admin automáticamente

**Login:**
1. Ve a http://grafana.kind.local
2. Click en **"Sign in with GitHub"**
3. Autoriza la app
4. Acceso como Admin ✅

**Configuración de GitHub OAuth App:**
- Homepage URL: `http://grafana.kind.local`
- Callback URL: `http://grafana.kind.local/login/github`

---

## 🎯 Targets de Prometheus

### Targets UP ✅

- ✅ Grafana
- ✅ Kube State Metrics
- ✅ Node Exporter
- ✅ AlertManager
- ✅ API Server
- ✅ CoreDNS
- ✅ Kubelet
- ✅ Prometheus Operator

### Targets DOWN (Normal en Kind) ⚠️

Los siguientes targets están DOWN porque Kind no expone estos puertos por defecto (comportamiento esperado):

- ⚠️ **kube-controller-manager** (puerto 10257) - `connection refused`
- ⚠️ **kube-scheduler** (puerto 10259) - `connection refused`
- ⚠️ **kube-proxy** (puerto 10249) - `connection refused`
- ⚠️ **etcd** (puerto 2381) - `connection refused`

**¿Por qué están DOWN?**

Kind (Kubernetes in Docker) **no expone estos puertos por seguridad y simplicidad**. Estos son componentes internos del control plane que se ejecutan dentro del contenedor de Kind pero no están accesibles externamente.

**¿Es un problema?**

❌ **NO es un problema**. Para monitorear **aplicaciones y workloads** (como Backstage), ya tienes todas las métricas necesarias de:

- ✅ **Kubelet** - Métricas de pods y containers
- ✅ **API Server** - Métricas de requests al API
- ✅ **Node Exporter** - Métricas del sistema operativo
- ✅ **Kube State Metrics** - Estado de todos los recursos K8s
- ✅ **CoreDNS** - Métricas de DNS

**¿Cómo solucionarlo (si realmente lo necesitas)?**

Solo necesario si quieres métricas profundas del control plane (muy raro en desarrollo):

1. **Opción 1 (Recomendada)**: Deshabilitar estos ServiceMonitors en Helm values:
```yaml
defaultRules:
  rules:
    kubeProxy: false
    kubeSchedulerAlerting: false
    kubeSchedulerRecording: false
    etcd: false
```

2. **Opción 2**: Reconfigurar Kind cluster para exponer puertos (requiere recrear cluster)

### Backstage Metrics ⏳

**Status:** Pendiente de configuración

Backstage por defecto no expone métricas Prometheus. Para habilitarlas:

1. **Instalar plugin de Prometheus**:
```bash
cd backstage-kind
yarn add @backstage/plugin-prometheus
```

2. **Configurar en app-config.yaml**:
```yaml
prometheus:
  enabled: true
  path: /metrics
  port: 7007
```

3. **Crear ServiceMonitor**:
```bash
kubectl apply -f monitoring/backstage-servicemonitor.yaml
```

---

## 📊 Acceso a Servicios

| Servicio | Ingress | Port Forward | Credenciales |
|----------|---------|--------------|--------------|
| **Prometheus** | http://prometheus.kind.local | `kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090` | N/A |
| **Grafana** | http://grafana.kind.local | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80` | ✅ GitHub OAuth |
| **AlertManager** | http://alertmanager.kind.local | `kubectl port-forward -n monitoring svc/prometheus-alertmanager 9093:9093` | N/A |

**Agregar a `/etc/hosts`:**
```bash
echo "127.0.0.1 prometheus.kind.local grafana.kind.local alertmanager.kind.local" | sudo tee -a /etc/hosts
```

---

## 🚨 Configurar Notificaciones

### Slack

1. **Crear Slack Incoming Webhook**
   - https://api.slack.com/messaging/webhooks

2. **Configurar AlertManager**:
```bash
kubectl create secret generic alertmanager-slack-webhook \
  -n monitoring \
  --from-literal=webhook-url='https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
```

3. **Actualizar configuración**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-config
  namespace: monitoring
stringData:
  alertmanager.yaml: |
    global:
      slack_api_url_file: /etc/alertmanager/secrets/alertmanager-slack-webhook/webhook-url

    route:
      group_by: ['alertname', 'cluster', 'namespace']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'slack'
      routes:
      - match:
          severity: critical
        receiver: slack-critical

    receivers:
    - name: 'slack'
      slack_configs:
      - channel: '#alerts'
        title: '{{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}\n{{ end }}'

    - name: 'slack-critical'
      slack_configs:
      - channel: '#critical-alerts'
        title: 'CRITICAL: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}\n{{ end }}'
```

4. **Aplicar configuración**:
```bash
kubectl apply -f alertmanager-config.yaml
kubectl delete pod -n monitoring -l app.kubernetes.io/name=alertmanager
```

---

## 📁 Archivos de Configuración

```
monitoring/
├── backstage-dashboard.json       # Dashboard de Grafana ✅
├── backstage-alerts.yaml          # PrometheusRule con alertas ✅
├── prometheus-pvc.yaml            # PVC de referencia (no usado - Operator gestiona storage automáticamente)
└── backstage-servicemonitor.yaml  # ServiceMonitor (pendiente - requiere plugin Prometheus en Backstage)
```

---

## 🛠️ Comandos Útiles

### Verificar Configuración

```bash
# Ver todas las alertas
kubectl get prometheusrule -n monitoring

# Ver targets de Prometheus
kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090
# http://localhost:9090/targets

# Ver alertas activas
# http://localhost:9090/alerts

# Ver configuración de Grafana
kubectl get configmap kube-prometheus-stack-grafana -n monitoring -o yaml

# Ver PVC de Prometheus
kubectl get pvc -n monitoring
```

### Logs

```bash
# Prometheus
kubectl logs -n monitoring prometheus-prometheus-prometheus-0 -c prometheus -f

# Grafana
kubectl logs -n monitoring deployment/kube-prometheus-stack-grafana -f

# AlertManager
kubectl logs -n monitoring alertmanager-prometheus-alertmanager-0 -c alertmanager -f
```

### Reiniciar Componentes

```bash
# Reiniciar Prometheus (después de cambios en alertas)
kubectl delete pod -n monitoring prometheus-prometheus-prometheus-0

# Reiniciar Grafana (después de cambios en config)
kubectl rollout restart deployment kube-prometheus-stack-grafana -n monitoring

# Reiniciar AlertManager (después de cambios en notificaciones)
kubectl delete pod -n monitoring alertmanager-prometheus-alertmanager-0
```

---

## 🔧 Troubleshooting

### Grafana OAuth no funciona

```bash
# 1. Verificar configuración
kubectl get configmap kube-prometheus-stack-grafana -n monitoring -o yaml | grep -A 20 auth.github

# 2. Verificar logs
kubectl logs -n monitoring deployment/kube-prometheus-stack-grafana -f

# 3. Asegurar callback URL en GitHub OAuth App
# Callback: http://grafana.kind.local/login/github

# 4. Reiniciar Grafana
kubectl rollout restart deployment kube-prometheus-stack-grafana -n monitoring
```

### Alertas no aparecen en Prometheus

```bash
# 1. Verificar PrometheusRule
kubectl get prometheusrule backstage-alerts -n monitoring -o yaml

# 2. Ver logs de Prometheus
kubectl logs -n monitoring prometheus-prometheus-prometheus-0 -c prometheus | grep -i error

# 3. Verificar label selector en Prometheus
kubectl get prometheus prometheus-prometheus -n monitoring -o yaml | grep -A 5 ruleSelector
```

### PVC no se crea

```bash
# 1. Verificar storageclass
kubectl get storageclass

# 2. Ver detalles del PVC
kubectl describe pvc prometheus-storage -n monitoring

# 3. Ver eventos
kubectl get events -n monitoring --sort-by='.lastTimestamp'
```

---

## 📚 Queries Útiles de Prometheus

### Backstage

```promql
# CPU usage
sum(rate(container_cpu_usage_seconds_total{namespace="backstage", pod=~"backstage-.*"}[5m])) by (pod)

# Memory usage
sum(container_memory_working_set_bytes{namespace="backstage", pod=~"backstage-.*"}) by (pod)

# Pod status
kube_pod_status_phase{namespace="backstage", pod=~"backstage-.*"}

# Restarts
kube_pod_container_status_restarts_total{namespace="backstage"}

# Network received
rate(container_network_receive_bytes_total{namespace="backstage"}[5m])

# Network transmitted
rate(container_network_transmit_bytes_total{namespace="backstage"}[5m])
```

### PostgreSQL

```promql
# Memory usage
container_memory_working_set_bytes{namespace="backstage", pod=~"psql-.*"}

# CPU usage
rate(container_cpu_usage_seconds_total{namespace="backstage", pod=~"psql-.*"}[5m])

# Pod status
kube_pod_status_phase{namespace="backstage", pod=~"psql-.*"}
```

### Cluster

```promql
# Total CPU usage
sum(rate(container_cpu_usage_seconds_total[5m]))

# Total memory usage
sum(container_memory_working_set_bytes)

# Pod count per namespace
count(kube_pod_info) by (namespace)

# Node CPU usage
sum(rate(node_cpu_seconds_total{mode!="idle"}[5m])) by (instance)

# Node memory usage
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes
```

---

## 🎯 Próximos Pasos

1. **Habilitar métricas de Backstage**
   - Instalar plugin Prometheus
   - Crear ServiceMonitor

2. **Configurar notificaciones**
   - Slack para alertas
   - Email para critical

3. **Dashboards adicionales**
   - Dashboard de ArgoCD
   - Dashboard de PostgreSQL
   - Dashboard de todo el namespace

4. **Long-term storage**
   - Considerar Thanos para almacenamiento a largo plazo
   - Exportar métricas a S3/GCS

5. **Logs centralizados**
   - Instalar Loki
   - Configurar Promtail
   - Integrar con Grafana

---

## 📚 Referencias

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana GitHub OAuth](https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/github/)
- [PrometheusRule CRD](https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.PrometheusRule)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

---

**Última actualización:** Octubre 11, 2025
**Maintainer:** Jaime Henao <jaime.andres.henao.arbelaez@ba.com>
**Status:** ✅ Configuración completa y funcional
