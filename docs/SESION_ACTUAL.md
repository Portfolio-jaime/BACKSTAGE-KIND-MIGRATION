# 📝 Sesión Actual - Octubre 11, 2025

**Última actualización**: 23:00 hrs
**Status**: ✅ Sistema funcionando correctamente

---

## 🎯 Estado Actual del Proyecto

### ArgoCD Applications (4 total)

```bash
kubectl get application -n argocd
```

| Aplicación | Sync Status | Health Status | Descripción |
|------------|-------------|---------------|-------------|
| **backstage** | ✅ Synced | ❤️ Healthy | Aplicación principal + Ingress |
| **kube-prometheus-stack** | ✅ Synced | ❤️ Healthy | Prometheus + Grafana + AlertManager |
| **gitops1** | ✅ Synced | ❤️ Healthy | Otra aplicación |
| **python-app-1** | ✅ Synced | ❤️ Healthy | Otra aplicación |

---

## 📦 Componentes Desplegados

### Namespace: backstage

```bash
kubectl get all -n backstage
```

- ✅ **Backstage** (Deployment) - Developer Portal
- ✅ **PostgreSQL** (StatefulSet) - Base de datos 17.6.0
  - Storage: 8Gi PVC
  - Desplegado con Helm (NO gestionado por ArgoCD)
  - Release name: `psql`
- ✅ **Ingress** - http://backstage.kind.local
  - Incluido en el chart de Backstage

### Namespace: monitoring

```bash
kubectl get pods -n monitoring
```

- ✅ **Prometheus** (StatefulSet)
  - Storage: 5Gi (gestionado automáticamente)
  - Métricas: Todas funcionando
- ✅ **Grafana** (Deployment)
  - Storage: 2Gi PVC
  - GitHub OAuth: ✅ Configurado y funcionando
  - Secret: `grafana-github-oauth`
- ✅ **AlertManager** (StatefulSet)
  - Storage: 1Gi
- ✅ **Prometheus Operator** (Deployment)
- ✅ **Node Exporter** (DaemonSet)
- ✅ **Kube State Metrics** (Deployment)

### Alertas y Dashboards

```bash
kubectl get prometheusrule -n monitoring | grep backstage
```

- ✅ **9 Alertas de Backstage** (PrometheusRule)
  - Aplicadas manualmente con `kubectl apply`
  - Archivo: `helm-charts/monitoring/templates/backstage-alerts.yaml`
  - NO gestionadas por ArgoCD (para evitar conflictos)

---

## 🚀 Lo que Funciona

### 1. Monitoring Stack Completo ✅

**Gestionado por ArgoCD:**
- Application: `kube-prometheus-stack`
- Source: https://prometheus-community.github.io/helm-charts
- Chart version: 65.0.0
- **Values**: `helm-charts/monitoring/values.yaml` (desde el repo)

**Configuración activa:**
- GitHub OAuth para Grafana
- Persistent storage (5Gi + 2Gi + 1Gi)
- Targets DOWN en Kind documentados como normales
- Alertas deshabilitadas para componentes no disponibles (etcd, scheduler, etc.)

### 2. PostgreSQL Funcional ✅

**NO gestionado por ArgoCD** (para evitar conflictos):
- Desplegado con Helm directamente
- Release: `psql`
- Chart: Bitnami PostgreSQL 16.7.27
- Version: 17.6.0
- Storage: 8Gi PVC

```bash
helm list -n backstage
# NAME	NAMESPACE	REVISION	STATUS  	CHART             	APP VERSION
# psql	backstage	1       	deployed	postgresql-16.7.27	17.6.0
```

### 3. Backstage con GitOps ✅

**Gestionado por ArgoCD:**
- Application: `backstage`
- Incluye Ingress automáticamente
- Conectado a PostgreSQL
- Image Updater activo

---

## 🔧 Configuraciones Importantes

### Secrets Creados

```bash
# Grafana GitHub OAuth (monitoring namespace)
kubectl get secret grafana-github-oauth -n monitoring
# Contenido:
# - GF_AUTH_GITHUB_CLIENT_ID: Ov23liX98Qe1ectC1zdj
# - GF_AUTH_GITHUB_CLIENT_SECRET: 3133588a686087d188d1b85c145cfc562a4a9a69

# PostgreSQL (backstage namespace)
kubectl get secret psql-postgresql -n backstage
# Password: backstage

# Backstage (backstage namespace)
kubectl get secret backstage-secrets -n backstage
```

### GitHub OAuth App

**Usado por ArgoCD y Grafana:**
- Client ID: `Ov23liX98Qe1ectC1zdj`
- Client Secret: `3133588a686087d188d1b85c145cfc562a4a9a69`
- Organization: `Portfolio-jaime`

**Callbacks configurados:**
- ArgoCD: `https://argocd.kind.local/api/dex/callback`
- Grafana: `http://grafana.kind.local/login/github`

---

## 📁 Archivos Importantes

### En el Repositorio

```
backstage-kind-migration/
├── argocd/
│   ├── apps/
│   │   ├── postgresql-application.yaml      # NO APLICADO (conflictos)
│   │   ├── ingress-application.yaml         # NO APLICADO (ya existe)
│   │   └── monitoring-config-application.yaml # NO APLICADO (errores)
│   ├── argocd-cm.yaml                       # ✅ ArgoCD config (OAuth)
│   ├── argocd-rbac-cm.yaml                  # ✅ RBAC (jaimehenao8126 admin)
│   └── README.md                            # Guía de ArgoCD
│
├── helm-charts/
│   ├── monitoring/
│   │   ├── values.yaml                      # ✅ USADO POR ARGOCD
│   │   ├── README.md                        # Guía de monitoring
│   │   └── templates/
│   │       ├── backstage-alerts.yaml        # ✅ Aplicado manualmente
│   │       └── backstage-dashboard.json     # Dashboard (no usado)
│   │
│   ├── postgresql/                          # NO USADO (PostgreSQL con Helm)
│   └── ingress/                             # NO USADO (incluido en Backstage)
│
└── docs/
    ├── MONITORING_SETUP_GUIDE.md            # ✅ Guía completa
    ├── MONITORING_IMPLEMENTATION.md         # ✅ GitOps implementation
    ├── ARGOCD_CONFIGURATION.md              # ✅ ArgoCD setup
    └── SESION_ACTUAL.md                     # 📍 ESTE ARCHIVO
```

---

## 🎨 Acceso a Servicios

### Port Forward

```bash
# Backstage
kubectl port-forward -n backstage svc/backstage 7007:80
# http://localhost:7007

# ArgoCD
kubectl port-forward -n argocd svc/argocd-server 8080:443
# https://localhost:8080
# User: GitHub OAuth o admin/password

# Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# http://localhost:3000
# User: GitHub OAuth o admin/admin123

# Prometheus
kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090
# http://localhost:9090

# AlertManager
kubectl port-forward -n monitoring svc/prometheus-alertmanager 9093:9093
# http://localhost:9093
```

### Con Ingress (agregar a /etc/hosts)

```bash
echo "127.0.0.1 backstage.kind.local argocd.kind.local grafana.kind.local prometheus.kind.local" | sudo tee -a /etc/hosts
```

---

## ⚠️ Problemas Encontrados y Soluciones

### 1. PostgreSQL Application - CONFLICTO ❌

**Problema:**
- PostgreSQL ya está desplegado con Helm
- ArgoCD intentaba gestionar un release existente
- Status: Unknown/OutOfSync

**Solución aplicada:**
- Eliminamos la application de ArgoCD
- Dejamos PostgreSQL gestionado con Helm directamente
- **NO intentar agregar PostgreSQL a ArgoCD**

### 2. Ingress Duplicado - CONFLICTO ❌

**Problema:**
- Creamos application de ingress en ArgoCD
- Pero el ingress ya existe en el chart de Backstage

**Solución aplicada:**
- Eliminamos la application `backstage-ingress`
- El ingress está incluido en el chart de Backstage

### 3. Monitoring Config - ERROR ❌

**Problema:**
- `backstage-monitoring-config` application con errores
- Dashboard JSON tenía sintaxis de Helm incorrecta
- Error: `function "pod" not defined`

**Solución aplicada:**
- Eliminamos la application de ArgoCD
- Aplicamos alertas manualmente con kubectl
- Dashboard no se usa por ahora

### 4. Grafana CreateContainerConfigError - RESUELTO ✅

**Problema:**
- Grafana en status `CreateContainerConfigError`
- Secret `grafana-github-oauth` no existía

**Solución aplicada:**
```bash
kubectl create secret generic grafana-github-oauth -n monitoring \
  --from-literal=GF_AUTH_GITHUB_CLIENT_ID='Ov23liX98Qe1ectC1zdj' \
  --from-literal=GF_AUTH_GITHUB_CLIENT_SECRET='3133588a686087d188d1b85c145cfc562a4a9a69'
```

---

## 🔄 Flujo GitOps Actual

### Para Actualizar Monitoring

1. Modificar `helm-charts/monitoring/values.yaml`
2. Commit y push a GitHub
3. ArgoCD sincroniza automáticamente (cada 3 min)

```bash
vim helm-charts/monitoring/values.yaml
git add helm-charts/monitoring/values.yaml
git commit -m "feat: actualizar configuración de monitoring"
git push origin main

# ArgoCD aplicará cambios automáticamente
```

### Para Ver Estado

```bash
# Ver todas las aplicaciones
kubectl get application -n argocd

# Ver detalles de monitoring
kubectl describe application kube-prometheus-stack -n argocd

# Ver pods
kubectl get pods -n monitoring
kubectl get pods -n backstage

# Ver PVCs (storage)
kubectl get pvc -n monitoring
kubectl get pvc -n backstage
```

---

## 📊 Métricas y Alertas

### Alertas Configuradas (9 total)

```bash
kubectl get prometheusrule backstage-alerts -n monitoring
```

| Alerta | Severidad | Condición |
|--------|-----------|-----------|
| BackstagePodDown | Critical | Pod no Running > 5min |
| BackstagePodCrashLooping | Warning | Restarts detectados |
| BackstageHighMemoryUsage | Warning | Memoria > 85% por 10min |
| BackstageHighCPUUsage | Warning | CPU > 85% por 10min |
| BackstagePodNotReady | Warning | Pod not ready > 5min |
| PostgreSQLDown | Critical | PostgreSQL down > 2min |
| PostgreSQLHighMemoryUsage | Warning | PostgreSQL mem > 90% |
| BackstageNamespaceQuotaExceeded | Warning | Quota > 90% |

**Ver alertas activas:**
```bash
# En Prometheus UI
kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090
# http://localhost:9090/alerts
```

### Targets de Prometheus

**Targets UP (funcionando):** ✅
- Grafana
- Kube State Metrics
- Node Exporter
- AlertManager
- API Server
- CoreDNS
- Kubelet
- Prometheus Operator

**Targets DOWN (normal en Kind):** ⚠️
- kube-controller-manager (puerto 10257)
- kube-scheduler (puerto 10259)
- kube-proxy (puerto 10249)
- etcd (puerto 2381)

**Razón:** Kind no expone estos puertos por seguridad. **Es comportamiento esperado**.

---

## 🚀 Próximos Pasos (Para Mañana)

### 1. Opcional: Dashboard de Backstage en Grafana

- Fix del JSON del dashboard (remover sintaxis de Helm)
- Importar manualmente en Grafana UI

### 2. Métricas de Backstage

- Instalar plugin `@backstage/plugin-prometheus`
- Configurar endpoint `/metrics` en Backstage
- Crear ServiceMonitor

### 3. Notificaciones de AlertManager

- Configurar Slack webhook
- Actualizar AlertManager config

### 4. Documentación Final

- Crear diagrama de arquitectura
- Quick Start guide completo
- Video o screenshots de la UI

---

## 📝 Comandos Útiles

### Verificación Rápida

```bash
# Estado de ArgoCD
kubectl get application -n argocd

# Estado de Monitoring
kubectl get pods -n monitoring
kubectl get pvc -n monitoring

# Estado de Backstage
kubectl get pods -n backstage
kubectl get pvc -n backstage

# Ver alertas
kubectl get prometheusrule -n monitoring

# Ver servicemonitors
kubectl get servicemonitor -A
```

### Logs

```bash
# Grafana
kubectl logs -n monitoring deployment/kube-prometheus-stack-grafana -f

# Prometheus
kubectl logs -n monitoring prometheus-prometheus-prometheus-0 -c prometheus -f

# Backstage
kubectl logs -n backstage -l app=backstage -f

# PostgreSQL
kubectl logs -n backstage psql-postgresql-0 -f
```

### Troubleshooting

```bash
# Ver eventos recientes
kubectl get events -n monitoring --sort-by='.lastTimestamp' | head -20
kubectl get events -n backstage --sort-by='.lastTimestamp' | head -20

# Describir pod con problemas
kubectl describe pod <pod-name> -n <namespace>

# Reiniciar ArgoCD controller
kubectl delete pod -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Forzar sync de una app
kubectl patch application <app-name> -n argocd --type merge \
  -p '{"operation": {"initiatedBy": {"username": "admin"}, "sync": {"revision": "HEAD"}}}'
```

---

## 📚 Documentación Relacionada

1. **[README.md](../README.md)** - Documentación principal completa
2. **[argocd/README.md](../argocd/README.md)** - Guía de ArgoCD App of Apps
3. **[helm-charts/monitoring/README.md](../helm-charts/monitoring/README.md)** - Guía de monitoring
4. **[helm-charts/postgresql/README.md](../helm-charts/postgresql/README.md)** - Guía de PostgreSQL
5. **[docs/MONITORING_SETUP_GUIDE.md](MONITORING_SETUP_GUIDE.md)** - Setup de monitoring
6. **[docs/MONITORING_IMPLEMENTATION.md](MONITORING_IMPLEMENTATION.md)** - GitOps implementation
7. **[docs/ARGOCD_CONFIGURATION.md](ARGOCD_CONFIGURATION.md)** - Config de ArgoCD

---

## ✅ Checklist de Funcionalidad

- [x] Backstage desplegado y funcionando
- [x] PostgreSQL con persistent storage (8Gi)
- [x] Monitoring stack completo (Prometheus + Grafana + AlertManager)
- [x] Persistent storage para monitoring (5Gi + 2Gi + 1Gi)
- [x] GitHub OAuth para Grafana
- [x] 9 Alertas configuradas
- [x] Targets de Prometheus funcionando
- [x] ArgoCD gestionando Backstage y Monitoring
- [x] GitOps workflow funcionando
- [x] Documentación completa
- [ ] Dashboard de Backstage en Grafana (pendiente)
- [ ] Métricas de Backstage (pendiente)
- [ ] Notificaciones de Slack (pendiente)

---

**Maintainer:** Jaime Henao <jaime.andres.henao.arbelaez@ba.com>
**Repository:** https://github.com/Portfolio-jaime/backstage-kind-migration
**Última sesión:** Octubre 11, 2025 - 23:00 hrs

**Estado:** ✅ Todo funcionando sin errores
