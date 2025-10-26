# 🔄 GitOps con ArgoCD - Backstage

## 📋 Overview

Este proyecto usa **GitOps** con **ArgoCD** para gestionar el deployment de Backstage de manera declarativa y automatizada.

### Flujo GitOps Completo

```
┌──────────────────────────────────────────────────────────────┐
│                    GITOPS WORKFLOW                            │
└──────────────────────────────────────────────────────────────┘

1. Developer Push Code
   ├─ git push origin main
   └─ Trigger GitHub Actions

2. CI/CD Pipeline (GitHub Actions)
   ├─ ✅ Build & Test
   ├─ ✅ Build Docker Image
   └─ ✅ Push to Docker Hub
       └─ jaimehenao8126/backstage-production:latest

3. ArgoCD Image Updater (Auto-detect)
   ├─ 🔍 Detect new image in Docker Hub
   ├─ 📝 Update helm/backstage/values.yaml in Git
   └─ 💾 Commit changes to repository

4. ArgoCD Application (Auto-sync)
   ├─ 🔄 Detect changes in Git
   ├─ 📦 Helm upgrade with new image
   ├─ 🚀 Rolling update in Kubernetes
   └─ ✅ Verify deployment health

5. Self-Healing
   ├─ 🔍 ArgoCD monitors cluster state
   ├─ 🔄 Auto-corrects any drift
   └─ ✅ Maintains desired state from Git
```

## 🚀 Quick Start

### 1. Instalar ArgoCD

```bash
# Ejecutar script de instalación
chmod +x scripts/setup-argocd.sh
./scripts/setup-argocd.sh
```

### 2. Acceder a ArgoCD UI

```bash
# Terminal 1: Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Terminal 2: Get password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

**Access:** https://localhost:8080
- **Username:** `admin`
- **Password:** (output del comando anterior)

### 3. Verificar Application

```bash
# Ver estado de la aplicación
kubectl get application backstage -n argocd

# Ver detalles
kubectl describe application backstage -n argocd

# Watch sync status
kubectl get application backstage -n argocd -w
```

## 📁 Estructura de Archivos GitOps

```
backstage-kind-migration/
├── argocd/
│   ├── apps/
│   │   └── backstage-application.yaml      # ArgoCD Application manifest
│   └── image-updater-config.yaml       # Image Updater configuration
│
├── helm/
│   └── backstage/
│       ├── Chart.yaml                   # Helm chart metadata
│       ├── values.yaml                  # 🎯 Source of truth for deployment
│       └── templates/                   # Kubernetes manifests
│
├── .github/workflows/
│   └── ci-cd.yaml                       # CI/CD pipeline
│
└── scripts/
    └── setup-argocd.sh                  # ArgoCD setup script
```

## 🔄 Flujo de Actualización Automática

### Cuando haces un cambio en el código:

1. **Push a GitHub**
   ```bash
   git add .
   git commit -m "feat: new feature"
   git push origin main
   ```

2. **GitHub Actions** (automático)
   - Build & Test
   - Docker build & push
   - Imagen: `jaimehenao8126/backstage-production:latest`

3. **ArgoCD Image Updater** (automático, cada 2 min)
   - Detecta nueva imagen en Docker Hub
   - Actualiza `helm/backstage/values.yaml`:
     ```yaml
     image:
       tag: "latest"  # o el SHA específico
     ```
   - Hace commit y push al repo

4. **ArgoCD** (automático)
   - Detecta cambio en Git
   - Ejecuta `helm upgrade`
   - Rolling update en Kubernetes
   - Verifica health checks

## ⚙️ Configuración de ArgoCD Application

El archivo `argocd/apps/backstage-application.yaml` define:

### Source (Fuente de Verdad)
```yaml
source:
  repoURL: https://github.com/Portfolio-jaime/BACKSTAGE-KIND-MIGRATION.git
  targetRevision: main
  path: helm/backstage
```

### Sync Policy (Política de Sincronización)
```yaml
syncPolicy:
  automated:
    selfHeal: true    # Auto-corrige drift
    prune: true       # Elimina recursos huérfanos
```

### Image Updater Annotations
```yaml
annotations:
  argocd-image-updater.argoproj.io/image-list: backstage=jaimehenao8126/backstage-production:latest
  argocd-image-updater.argoproj.io/backstage.update-strategy: latest
```

## 🔍 Monitoreo

### ArgoCD CLI

```bash
# Install ArgoCD CLI
brew install argocd  # macOS
# o descargar desde https://github.com/argoproj/argo-cd/releases

# Login
argocd login localhost:8080

# Ver aplicaciones
argocd app list

# Ver estado de Backstage
argocd app get backstage

# Sync manual (si es necesario)
argocd app sync backstage

# Ver logs
argocd app logs backstage

# Ver diff
argocd app diff backstage
```

### Kubectl

```bash
# Ver Application
kubectl get application backstage -n argocd -o yaml

# Ver sync status
kubectl get application backstage -n argocd \
  -o jsonpath='{.status.sync.status}'

# Ver health status
kubectl get application backstage -n argocd \
  -o jsonpath='{.status.health.status}'

# Ver eventos
kubectl get events -n argocd --sort-by='.lastTimestamp'
```

### ArgoCD UI

1. **Applications view**: Ver todas las apps
2. **Application details**: Click en "backstage"
   - 📊 Sync status
   - ❤️ Health status
   - 🌳 Resource tree
   - 📝 Eventos y logs
   - 🔄 History de syncs

## 🛠️ Troubleshooting

### Application no sincroniza

```bash
# Ver por qué no sincroniza
kubectl describe application backstage -n argocd

# Forzar sync
argocd app sync backstage --force

# O desde kubectl
kubectl patch application backstage -n argocd \
  --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

### Image Updater no detecta nueva imagen

```bash
# Ver logs del Image Updater
kubectl logs -f deployment/argocd-image-updater -n argocd

# Verificar configuración
kubectl get configmap argocd-image-updater-config -n argocd -o yaml

# Force update
kubectl annotate application backstage -n argocd \
  argocd-image-updater.argoproj.io/image-list=backstage=jaimehenao8126/backstage-production:latest \
  --overwrite
```

### Sync falla

```bash
# Ver logs de sync
argocd app logs backstage --follow

# Ver detalles del error
kubectl get application backstage -n argocd -o yaml | grep -A 20 status

# Rollback a versión anterior
argocd app rollback backstage
```

## 🔐 Secrets Management

Los secrets NO se gestionan con GitOps por seguridad. Se manejan con:

1. **Kubernetes Secrets** (ya existentes)
   ```bash
   kubectl get secret backstage-secrets -n backstage
   ```

2. **Sealed Secrets** (recomendado para producción)
   ```bash
   # Install Sealed Secrets controller
   kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml
   ```

3. **External Secrets Operator** (integración con Vault, AWS Secrets Manager, etc.)

## 📊 Métricas y Dashboards

### Prometheus Metrics

ArgoCD expone métricas en formato Prometheus:

```bash
# Port forward Prometheus
kubectl port-forward svc/argocd-metrics -n argocd 8082:8082

# Métricas disponibles en:
# http://localhost:8082/metrics
```

### Grafana Dashboards

ArgoCD tiene dashboards oficiales para Grafana:
- ArgoCD Overview
- ArgoCD Application Stats
- ArgoCD Notifications

## 🎯 Best Practices

### 1. **Branch Strategy**

```
main (production)
  └─ ArgoCD auto-sync enabled

develop (staging)
  └─ ArgoCD auto-sync enabled
  └─ Separate ArgoCD Application
```

### 2. **Image Tags**

```yaml
# ✅ Recomendado: Semantic versioning
image:
  tag: v1.2.3

# ✅ Alternativa: SHA
image:
  tag: main-a589e41

# ⚠️  Usar con cuidado: latest
image:
  tag: latest  # Solo con Image Updater
```

### 3. **Sync Waves**

Para controlar orden de deployment:

```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"  # Database primero
    argocd.argoproj.io/sync-wave: "2"  # App después
```

### 4. **Health Checks**

Asegurar que tus Deployments tengan health checks:

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 7007

readinessProbe:
  httpGet:
    path: /healthz
    port: 7007
```

## 🚨 Rollback

### Opción 1: ArgoCD History

```bash
# Ver history
argocd app history backstage

# Rollback a revisión específica
argocd app rollback backstage 5
```

### Opción 2: Git Revert

```bash
# Revertir commit que causó el problema
git revert <commit-hash>
git push origin main

# ArgoCD auto-sincronizará
```

### Opción 3: Manual Helm

```bash
# Rollback con Helm
helm rollback backstage -n backstage
```

## 📚 Recursos

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Image Updater](https://argocd-image-updater.readthedocs.io/)
- [GitOps Principles](https://opengitops.dev/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)

---

**Última actualización:** Octubre 11, 2025
**Maintainer:** Jaime Henao <jaime.andres.henao.arbelaez@ba.com>
