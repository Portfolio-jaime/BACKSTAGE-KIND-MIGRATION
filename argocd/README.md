# 🚀 ArgoCD Applications - GitOps Platform

Configuración completa de ArgoCD para gestionar toda la plataforma Backstage con GitOps.

## 📋 Arquitectura - App of Apps Pattern

```
backstage-platform (Root App)
├── postgresql (sync-wave: 1)
├── backstage (sync-wave: 2)
├── backstage-ingress (sync-wave: 3)
├── kube-prometheus-stack (sync-wave: 4)
└── backstage-monitoring-config (sync-wave: 5)
```

## 🎯 Aplicaciones Gestionadas

### 1. **backstage-platform** (Root Application)
**Path**: `argocd/root-application.yaml`
**Description**: Application principal que gestiona todas las demás (App of Apps pattern)

```bash
kubectl apply -f argocd/root-application.yaml
```

### 2. **postgresql**
**Path**: `helm-charts/postgresql`
**Sync Wave**: 1 (se despliega primero)
**Description**: Base de datos PostgreSQL 17.6.0 con Bitnami chart

**Recursos**:
- StatefulSet (1 replica)
- PVC (8Gi)
- Services (ClusterIP + Headless)
- ServiceMonitor (Prometheus metrics)
- Secret con credenciales

### 3. **backstage**
**Path**: `helm-charts/backstage`
**Sync Wave**: 2 (después de PostgreSQL)
**Description**: Aplicación principal de Backstage

**Recursos**:
- Deployment (1 replica)
- Service (ClusterIP)
- ConfigMaps (configuración)
- Secret (credenciales y OAuth)

### 4. **backstage-ingress**
**Path**: `helm-charts/ingress`
**Sync Wave**: 3 (después de Backstage)
**Description**: Ingress para acceso externo a Backstage

**Recursos**:
- Ingress (nginx)
- Host: `backstage.kind.local`

### 5. **kube-prometheus-stack**
**Path**: `helm-charts/monitoring/values.yaml`
**Sync Wave**: 4
**Description**: Stack completo de monitoreo

**Recursos**:
- Prometheus (5Gi storage)
- Grafana (2Gi storage, GitHub OAuth)
- AlertManager (1Gi storage)
- Prometheus Operator
- Node Exporter
- Kube State Metrics

### 6. **backstage-monitoring-config**
**Path**: `helm-charts/monitoring/templates`
**Sync Wave**: 5 (después del stack)
**Description**: Alertas y dashboards personalizados

**Recursos**:
- PrometheusRule (9 alertas)
- ConfigMap (dashboard de Backstage)

## 🚀 Despliegue

### Opción 1: App of Apps (Recomendado)

Desplegar solo la aplicación raíz, que desplegará todas las demás automáticamente:

```bash
kubectl apply -f argocd/root-application.yaml
```

### Opción 2: Individual

Desplegar aplicaciones manualmente en orden:

```bash
# 1. PostgreSQL
kubectl apply -f argocd/apps/postgresql-application.yaml

# 2. Backstage
kubectl apply -f argocd/apps/backstage-application.yaml

# 3. Ingress
kubectl apply -f argocd/apps/ingress-application.yaml

# 4. Monitoring
kubectl apply -f argocd/apps/monitoring-application.yaml
kubectl apply -f argocd/apps/monitoring-config-application.yaml
```

## 🔄 Sync Waves

Las aplicaciones se despliegan en orden usando `sync-wave`:

| Wave | Application | Descripción |
|------|-------------|-------------|
| 0 | backstage-platform | Root app |
| 1 | postgresql | Database primero |
| 2 | backstage | App después de DB |
| 3 | backstage-ingress | Ingress después de app |
| 4 | kube-prometheus-stack | Monitoring stack |
| 5 | backstage-monitoring-config | Configuraciones de monitoring |

## 📊 Ver Estado

### Con kubectl

```bash
# Ver todas las aplicaciones
kubectl get application -n argocd

# Ver detalles de una aplicación
kubectl describe application backstage-platform -n argocd

# Ver sync status
kubectl get application -n argocd -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.sync.status}{"\t"}{.status.health.status}{"\n"}{end}'
```

### Con ArgoCD CLI

```bash
# Ver todas las aplicaciones
argocd app list

# Ver detalles
argocd app get backstage-platform

# Ver árbol de recursos
argocd app get backstage-platform --show-operation

# Ver logs de sync
argocd app logs backstage-platform
```

### Con UI

```bash
# Port forward a ArgoCD UI
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Abrir en navegador
open https://localhost:8080
```

## 🔄 GitOps Workflow

### 1. Modificar Configuración

```bash
# Ejemplo: Actualizar recursos de PostgreSQL
vim helm-charts/postgresql/values.yaml
```

### 2. Commit y Push

```bash
git add helm-charts/postgresql/values.yaml
git commit -m "feat: aumentar recursos de PostgreSQL"
git push origin main
```

### 3. Sync Automático

ArgoCD detecta el cambio y sincroniza automáticamente (cada 3 minutos por defecto).

### 4. Forzar Sync Manual (Opcional)

```bash
argocd app sync backstage-platform
# O sincronizar app específica
argocd app sync postgresql
```

## 🎯 Health Checks

ArgoCD verifica el health de los recursos:

- ✅ **Healthy**: Todos los recursos están funcionando
- 🔄 **Progressing**: Recursos en proceso de creación/actualización
- ⚠️ **Degraded**: Algunos recursos tienen problemas
- ❌ **Missing**: Recursos esperados no existen

### Custom Health Checks

```yaml
# En cada application.yaml
ignoreDifferences:
  - group: apps
    kind: StatefulSet
    jsonPointers:
      - /spec/volumeClaimTemplates
```

## 📁 Estructura de Directorios

```
argocd/
├── README.md                              # Esta documentación
├── root-application.yaml                  # App of Apps principal
├── apps/                                  # Directorio de aplicaciones
│   ├── postgresql-application.yaml
│   ├── backstage-application.yaml
│   ├── ingress-application.yaml
│   ├── monitoring-application.yaml
│   └── monitoring-config-application.yaml
├── argocd-cm.yaml                         # ConfigMap de ArgoCD (OAuth GitHub)
├── argocd-rbac-cm.yaml                    # RBAC de ArgoCD
├── github-repo-secret.yaml                # Secret para acceso al repo
└── image-updater-config.yaml              # Config de image updater
```

## 🔐 Secrets Management

### Current Setup

Los secrets están gestionados en el cluster:

```bash
# Backstage
kubectl get secret backstage-secrets -n backstage

# PostgreSQL
kubectl get secret psql-postgresql -n backstage

# Grafana GitHub OAuth
kubectl get secret grafana-github-oauth -n monitoring
```

### Future: Sealed Secrets (Recomendado)

Para versionar secrets en Git de forma segura:

```bash
# Instalar Sealed Secrets
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Crear sealed secret
kubectl create secret generic backstage-secrets \
  --from-literal=POSTGRES_PASSWORD=backstage \
  --dry-run=client -o yaml | \
  kubeseal -o yaml > backstage-sealed-secret.yaml

# Versionar en Git
git add backstage-sealed-secret.yaml
```

## 🛠️ Troubleshooting

### Application OutOfSync

```bash
# Ver diferencias
argocd app diff backstage-platform

# Forzar refresh
argocd app get backstage-platform --refresh

# Hard refresh (ignorar cache)
argocd app get backstage-platform --hard-refresh
```

### Application Degraded

```bash
# Ver recursos con problemas
argocd app get backstage-platform --show-operation

# Ver logs
argocd app logs backstage-platform

# Ver eventos de K8s
kubectl get events -n backstage --sort-by='.lastTimestamp'
```

### Sync Failed

```bash
# Ver detalles del error
argocd app get backstage-platform

# Retry sync
argocd app sync backstage-platform --retry-limit 5

# Force sync (eliminar y recrear recursos)
argocd app sync backstage-platform --force
```

### Prune Issues

```bash
# Ver recursos que serían eliminados
argocd app diff backstage-platform --local-repo-root .

# Deshabilitar prune temporalmente
kubectl patch application backstage-platform -n argocd \
  --type merge -p '{"spec":{"syncPolicy":{"automated":{"prune":false}}}}'
```

## 📚 Referencias

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [App of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [Sync Waves](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/)
- [Health Assessment](https://argo-cd.readthedocs.io/en/stable/operator-manual/health/)

---

**Maintainer**: Jaime Henao <jaime.andres.henao.arbelaez@ba.com>
**Repository**: https://github.com/Portfolio-jaime/backstage-kind-migration
**Última actualización**: Octubre 11, 2025
