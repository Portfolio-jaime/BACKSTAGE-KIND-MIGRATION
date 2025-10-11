# 📊 Monitoring Stack - Configuración Completa

**Fecha:** Octubre 11, 2025
**Proyecto:** Backstage Kind Migration with GitOps
**Maintainer:** Jaime Henao <jaime.andres.henao.arbelaez@ba.com>

---

## 📋 Índice

1. [Stack Desplegado](#stack-desplegado)
2. [Prometheus](#prometheus)
3. [Grafana](#grafana)
4. [AlertManager](#alertmanager)
5. [Métricas de Backstage](#métricas-de-backstage)
6. [Acceso](#acceso)
7. [Dashboards](#dashboards)
8. [Alertas](#alertas)

---

## 🎯 Stack Desplegado

### Componentes

```
monitoring namespace:
├── Prometheus (StatefulSet)
│   ├── prometheus-prometheus-prometheus-0
│   └── Service: prometheus-prometheus:9090
│
├── Grafana (Deployment)
│   ├── kube-prometheus-stack-grafana-*
│   └── Service: kube-prometheus-stack-grafana:80
│
├── AlertManager (StatefulSet)
│   ├── alertmanager-prometheus-alertmanager-0
│   └── Service: prometheus-alertmanager:9093
│
├── Prometheus Operator (Deployment)
│   └── prometheus-operator-*
│
├── Kube State Metrics (Deployment)
│   └── kube-prometheus-stack-kube-state-metrics-*
│
└── Node Exporter (DaemonSet)
    └── kube-prometheus-stack-prometheus-node-exporter-*
```

### Estado Actual

```bash
# Verificar estado de todos los pods
kubectl get pods -n monitoring

NAME                                                        READY   STATUS    RESTARTS   AGE
alertmanager-prometheus-alertmanager-0                      2/2     Running   16         11d
kube-prometheus-stack-grafana-68b6849db7-lrgzp              3/3     Running   25         11d
kube-prometheus-stack-kube-state-metrics-645496fcd7-zxz8x   1/1     Running   126        11d
kube-prometheus-stack-prometheus-node-exporter-qzvdx        1/1     Running   118        11d
prometheus-operator-5589b55cdb-846zd                        1/1     Running   96         11d
prometheus-prometheus-prometheus-0                          2/2     Running   30         11d
```

---

## 🔥 Prometheus

### Configuración

**Version**: Prometheus v2.x (managed by Operator)
**Storage**: EmptyDir (datos se pierden al reiniciar)
**Retention**: 10d
**Scrape Interval**: 30s

### ServiceMonitors Configurados

```bash
kubectl get servicemonitor -A

NAMESPACE    NAME                                             AGE
monitoring   kube-prometheus-stack-grafana                    11d
monitoring   kube-prometheus-stack-kube-state-metrics         11d
monitoring   kube-prometheus-stack-prometheus-node-exporter   11d
monitoring   prometheus-alertmanager                          11d
monitoring   prometheus-apiserver                             11d
monitoring   prometheus-coredns                               11d
monitoring   prometheus-kube-controller-manager               11d
monitoring   prometheus-kube-etcd                             11d
monitoring   prometheus-kube-proxy                            11d
monitoring   prometheus-kube-scheduler                        11d
monitoring   prometheus-kubelet                               11d
monitoring   prometheus-operator                              11d
monitoring   prometheus-prometheus                            11d
backstage    backstage                                        11d  ✅
```

### Métricas Recolectadas

**Kubernetes:**
- Node metrics (CPU, memoria, disco, red)
- Pod metrics (recursos, estados, eventos)
- Container metrics (CPU, memoria por container)
- Kubelet metrics
- API Server metrics
- Controller Manager metrics
- Scheduler metrics
- CoreDNS metrics

**Backstage:**
- HTTP request duration
- HTTP request count
- HTTP request errors
- Node.js process metrics
- Event loop lag
- Database connections

**ArgoCD:**
- Application sync status
- Repository health
- API server metrics

### Acceso a Prometheus

#### Método 1: Ingress
```bash
# URL: http://prometheus.kind.local
# Agregar a /etc/hosts:
echo "127.0.0.1 prometheus.kind.local" | sudo tee -a /etc/hosts
```

#### Método 2: Port Forward
```bash
kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090
# http://localhost:9090
```

### Queries Útiles

```promql
# CPU usage por pod
sum(rate(container_cpu_usage_seconds_total{namespace="backstage"}[5m])) by (pod)

# Memoria usage por pod
sum(container_memory_working_set_bytes{namespace="backstage"}) by (pod)

# HTTP requests por segundo (Backstage)
rate(http_requests_total{namespace="backstage"}[5m])

# Errores HTTP (Backstage)
rate(http_requests_total{namespace="backstage",status=~"5.."}[5m])

# ArgoCD sync status
argocd_app_info{namespace="argocd"}
```

---

## 📈 Grafana

### Configuración

**Version**: Grafana v10.x
**Admin User**: `admin`
**Admin Password**: `admin123`

### Datasources Configurados

1. **Prometheus** (default)
   - URL: http://prometheus-prometheus:9090
   - Access: Server (proxy)

### Acceso a Grafana

#### Método 1: Ingress
```bash
# URL: http://grafana.kind.local
# Agregar a /etc/hosts:
echo "127.0.0.1 grafana.kind.local" | sudo tee -a /etc/hosts
```

#### Método 2: Port Forward
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# http://localhost:3000
# Usuario: admin
# Password: admin123
```

### Dashboards Disponibles

**Por defecto (desde kube-prometheus-stack):**

1. **Kubernetes / Compute Resources / Cluster**
   - Vista general del cluster
   - CPU, memoria, red por namespace

2. **Kubernetes / Compute Resources / Namespace (Pods)**
   - Recursos por pod en un namespace
   - Útil para ver Backstage

3. **Kubernetes / Compute Resources / Pod**
   - Detalles de un pod específico
   - CPU, memoria, red, disco

4. **Kubernetes / Networking / Cluster**
   - Métricas de red del cluster
   - Tráfico, errores, latencia

5. **Node Exporter / Nodes**
   - Métricas del nodo
   - CPU, memoria, disco, red

6. **Prometheus / Overview**
   - Estado de Prometheus
   - Targets, rules, storage

### Crear Dashboard para Backstage

```json
{
  "dashboard": {
    "title": "Backstage Monitoring",
    "panels": [
      {
        "title": "HTTP Request Rate",
        "targets": [
          {
            "expr": "rate(http_requests_total{namespace=\"backstage\"}[5m])"
          }
        ]
      },
      {
        "title": "HTTP Request Duration",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{namespace=\"backstage\"}[5m]))"
          }
        ]
      },
      {
        "title": "Memory Usage",
        "targets": [
          {
            "expr": "sum(container_memory_working_set_bytes{namespace=\"backstage\", pod=~\"backstage-.*\"}) by (pod)"
          }
        ]
      },
      {
        "title": "CPU Usage",
        "targets": [
          {
            "expr": "sum(rate(container_cpu_usage_seconds_total{namespace=\"backstage\", pod=~\"backstage-.*\"}[5m])) by (pod)"
          }
        ]
      }
    ]
  }
}
```

### Importar Dashboards

**Dashboards recomendados de Grafana.com:**

- **15661**: Kubernetes Cluster Monitoring
- **13770**: Kubernetes Pods Monitoring
- **12006**: Kubernetes apiserver
- **11074**: Node Exporter for Prometheus

**Importar:**
```bash
# En Grafana UI:
# 1. Click en "+" > Import
# 2. Enter dashboard ID (ej: 15661)
# 3. Select Prometheus datasource
# 4. Import
```

---

## 🚨 AlertManager

### Configuración

**Version**: AlertManager v0.26.x
**Replicas**: 1
**Port**: 9093

### Acceso a AlertManager

#### Método 1: Ingress
```bash
# URL: http://alertmanager.kind.local
# Agregar a /etc/hosts:
echo "127.0.0.1 alertmanager.kind.local" | sudo tee -a /etc/hosts
```

#### Método 2: Port Forward
```bash
kubectl port-forward -n monitoring svc/prometheus-alertmanager 9093:9093
# http://localhost:9093
```

### Alertas Configuradas

```bash
kubectl get prometheusrule -n monitoring

# Reglas principales:
- Watchdog (always firing, health check)
- KubeAPIDown
- KubeletDown
- NodeNotReady
- PodCrashLooping
- HighMemoryUsage
- HighCPUUsage
```

### Configurar Alertas para Backstage

Crear PrometheusRule:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: backstage-alerts
  namespace: monitoring
spec:
  groups:
  - name: backstage
    interval: 30s
    rules:
    - alert: BackstagePodDown
      expr: up{namespace="backstage",job="backstage"} == 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Backstage pod is down"
        description: "Backstage pod {{ $labels.pod }} has been down for more than 5 minutes."

    - alert: BackstageHighMemory
      expr: container_memory_working_set_bytes{namespace="backstage",pod=~"backstage-.*"} > 1.5e9
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Backstage high memory usage"
        description: "Backstage pod {{ $labels.pod }} is using {{ $value | humanize }}B of memory."

    - alert: BackstageHighErrorRate
      expr: rate(http_requests_total{namespace="backstage",status=~"5.."}[5m]) > 0.05
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High error rate in Backstage"
        description: "Backstage is experiencing {{ $value | humanizePercentage }} error rate."
```

### Configurar Notificaciones

**Slack:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-config
  namespace: monitoring
stringData:
  alertmanager.yaml: |
    global:
      slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'

    route:
      group_by: ['alertname', 'cluster']
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
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

    - name: 'slack-critical'
      slack_configs:
      - channel: '#critical-alerts'
        title: 'CRITICAL: {{ .GroupLabels.alertname }}'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

---

## 📊 Métricas de Backstage

### ServiceMonitor Configurado

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: backstage
  namespace: backstage
spec:
  selector:
    matchLabels:
      app: backstage
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
```

### Endpoint de Métricas

**URL**: `http://backstage:7007/metrics`

### Métricas Expuestas por Backstage

```
# Node.js process metrics
process_cpu_user_seconds_total
process_cpu_system_seconds_total
process_resident_memory_bytes
process_heap_bytes

# Event loop
nodejs_eventloop_lag_seconds
nodejs_eventloop_lag_min_seconds
nodejs_eventloop_lag_max_seconds

# HTTP metrics
http_request_duration_seconds
http_requests_total
http_request_size_bytes
http_response_size_bytes

# Backstage specific
backstage_catalog_entities_count
backstage_catalog_processing_duration_seconds
```

### Verificar Métricas

```bash
# Ver si Prometheus está scrapeando Backstage
kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090

# En Prometheus UI (http://localhost:9090):
# Status > Targets
# Buscar: backstage/backstage/0
# State: UP ✅

# Probar query:
up{namespace="backstage"}
```

---

## 🛠️ Comandos Útiles

### Ver Estado del Stack

```bash
# Ver todos los recursos
kubectl get all -n monitoring

# Ver ServiceMonitors
kubectl get servicemonitor -A

# Ver PrometheusRules
kubectl get prometheusrule -n monitoring

# Ver targets de Prometheus
kubectl get prometheus -n monitoring -o yaml
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
# Restart Prometheus
kubectl delete pod -n monitoring prometheus-prometheus-prometheus-0

# Restart Grafana
kubectl rollout restart deployment/kube-prometheus-stack-grafana -n monitoring

# Restart AlertManager
kubectl delete pod -n monitoring alertmanager-prometheus-alertmanager-0
```

### Backup y Restore

```bash
# Exportar Grafana dashboards
kubectl exec -n monitoring deployment/kube-prometheus-stack-grafana -- \
  grafana-cli admin export-dashboard > grafana-dashboards-backup.json

# Exportar configuración de Prometheus
kubectl get prometheus -n monitoring prometheus-prometheus -o yaml > prometheus-config-backup.yaml

# Exportar alertas
kubectl get prometheusrule -n monitoring -o yaml > prometheus-rules-backup.yaml
```

---

## 🎯 Mejoras Recomendadas

### 1. Persistent Storage para Prometheus

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus-storage
  namespace: monitoring
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
```

### 2. Grafana OAuth con GitHub

Similar a ArgoCD, configurar GitHub OAuth para Grafana.

### 3. Thanos para Long-term Storage

Integrar Thanos para almacenamiento de métricas a largo plazo.

### 4. Loki para Logs

Agregar Loki stack para centralizar logs.

### 5. Dashboards Personalizados

Crear dashboards específicos para:
- Backstage performance
- ArgoCD sync status
- PostgreSQL metrics
- Kubernetes resources por namespace

---

## 📚 URLs de Acceso

| Servicio | Ingress | Port Forward | Credenciales |
|----------|---------|--------------|--------------|
| **Prometheus** | http://prometheus.kind.local | `kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090` | N/A |
| **Grafana** | http://grafana.kind.local | `kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80` | admin / admin123 |
| **AlertManager** | http://alertmanager.kind.local | `kubectl port-forward -n monitoring svc/prometheus-alertmanager 9093:9093` | N/A |

---

## 🔧 Troubleshooting

### Prometheus no scrapea Backstage

```bash
# 1. Verificar ServiceMonitor
kubectl get servicemonitor backstage -n backstage -o yaml

# 2. Verificar Service tiene el label correcto
kubectl get svc backstage -n backstage -o yaml | grep -A 5 labels

# 3. Verificar endpoint está accesible
kubectl run test --rm -it --image=curlimages/curl -- \
  curl http://backstage.backstage:7007/metrics

# 4. Ver logs de Prometheus
kubectl logs -n monitoring prometheus-prometheus-prometheus-0 -c prometheus | grep backstage
```

### Grafana no muestra datos

```bash
# 1. Verificar datasource
kubectl exec -n monitoring deployment/kube-prometheus-stack-grafana -- \
  grafana-cli admin data-sources list

# 2. Test query en Prometheus primero
kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090
# http://localhost:9090

# 3. Verificar time range en dashboard
```

### AlertManager no envía notificaciones

```bash
# 1. Verificar configuración
kubectl get secret alertmanager-config -n monitoring -o yaml

# 2. Ver logs
kubectl logs -n monitoring alertmanager-prometheus-alertmanager-0 -c alertmanager

# 3. Test alert manualmente
kubectl exec -n monitoring alertmanager-prometheus-alertmanager-0 -c alertmanager -- \
  amtool alert add test severity=warning
```

---

## 📚 Referencias

- [Prometheus Operator](https://prometheus-operator.dev/)
- [kube-prometheus-stack Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Grafana Documentation](https://grafana.com/docs/)
- [AlertManager Documentation](https://prometheus.io/docs/alerting/latest/alertmanager/)

---

**Última actualización:** Octubre 11, 2025
**Maintainer:** Jaime Henao <jaime.andres.henao.arbelaez@ba.com>
**Status:** ✅ Stack completo y funcional
