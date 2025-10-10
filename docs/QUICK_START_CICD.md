# 🚀 Quick Start - CI/CD Setup

## ⚡ Setup Rápido (5 minutos)

### 1. Configurar GitHub Secrets

```bash
# Opción A: Automático (recomendado)
./scripts/setup-github-secrets.sh your-username/backstage-kind-migration

# Opción B: Manual
# Ir a: Settings → Secrets and variables → Actions
# Agregar los secrets según .github/SETUP_SECRETS.md
```

### 2. Crear Branches

```bash
# Asegúrate de tener las branches principales
git checkout -b develop
git push origin develop

git checkout main
git push origin main
```

### 3. Configurar Branch Protection (Opcional)

En GitHub:
```
Settings → Branches → Add rule
├─ Branch: main
├─ ☑ Require pull request reviews
├─ ☑ Require status checks (PR Checks)
└─ ☑ Require branches up to date
```

### 4. Primer Deploy

```bash
# Push a develop para testing
git checkout develop
git add .
git commit -m "feat: setup CI/CD pipeline"
git push origin develop

# Monitorear en: https://github.com/your-user/backstage-kind-migration/actions
```

---

## 📊 Flujo Visual Completo

```
┌─────────────────────────────────────────────────────────────┐
│                      DEVELOPER WORKFLOW                      │
└─────────────────────────────────────────────────────────────┘

Local Development
┌─────────────────┐
│  Developer PC   │
│                 │
│  1. Code change │───► git checkout -b feature/new-auth
│  2. Test local  │───► make build && make build-docker
│  3. Commit      │───► git commit -m "feat: add feature"
│  4. Push        │───► git push origin feature/new-auth
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                      GITHUB PULL REQUEST                     │
└─────────────────────────────────────────────────────────────┘

Create PR: feature/new-auth → develop
         │
         ▼
┌──────────────────────────────────────────────────────────────┐
│  🔍 GitHub Actions: PR Checks (.github/workflows/pr-checks)  │
├──────────────────────────────────────────────────────────────┤
│  ✓ Job 1: Lint and Test (3 min)                             │
│    ├─ Backend lint                                           │
│    ├─ Frontend lint                                          │
│    ├─ Backend tests                                          │
│    └─ Frontend tests                                         │
│                                                              │
│  ✓ Job 2: Build Check (4 min)                               │
│    ├─ yarn workspace backend build                          │
│    └─ yarn workspace app build                              │
│                                                              │
│  ✓ Job 3: Helm Lint (1 min)                                 │
│    ├─ helm lint ./helm/backstage                            │
│    └─ helm template validation                              │
│                                                              │
│  ✓ Job 4: Docker Build Test (5 min)                         │
│    └─ Build image (no push)                                 │
│                                                              │
│  ✅ All Checks Passed → Ready to Merge                       │
└──────────────────────────────────────────────────────────────┘
         │
         │ 👍 Approve & Merge
         ▼
┌─────────────────────────────────────────────────────────────┐
│                    DEVELOPMENT DEPLOYMENT                    │
└─────────────────────────────────────────────────────────────┘

Merged to: develop
         │
         ▼
┌───────────────────────────────────────────────────────────────┐
│  🚀 GitHub Actions: CI/CD (.github/workflows/ci-cd.yaml)     │
│     Trigger: push to develop                                  │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  Job 1: BUILD (6-8 min)                                       │
│  ═══════════════════════════                                  │
│                                                               │
│  ┌────────────────────────────────────────┐                  │
│  │ 1. Checkout code                       │                  │
│  │    git clone + checkout develop        │                  │
│  └────────────────────────────────────────┘                  │
│           ▼                                                   │
│  ┌────────────────────────────────────────┐                  │
│  │ 2. Setup Environment                   │                  │
│  │    - Node.js 20                        │                  │
│  │    - Yarn cache                        │                  │
│  └────────────────────────────────────────┘                  │
│           ▼                                                   │
│  ┌────────────────────────────────────────┐                  │
│  │ 3. Install & Test                      │                  │
│  │    yarn install                        │                  │
│  │    yarn lint                           │                  │
│  │    yarn test                           │                  │
│  └────────────────────────────────────────┘                  │
│           ▼                                                   │
│  ┌────────────────────────────────────────┐                  │
│  │ 4. Build Application                   │                  │
│  │    yarn workspace backend build        │                  │
│  │    yarn workspace app build            │                  │
│  └────────────────────────────────────────┘                  │
│           ▼                                                   │
│  ┌────────────────────────────────────────┐                  │
│  │ 5. Docker Build & Push                 │                  │
│  │    - Login to Docker Hub               │                  │
│  │    - Build image (Dockerfile.kind)     │                  │
│  │    - Tag: develop-abc1234              │                  │
│  │    - Push to Docker Hub                │                  │
│  └────────────────────────────────────────┘                  │
│                                                               │
│  ✅ Build Complete                                            │
│  📦 Image: jaimehenao8126/backstage-production:develop-sha   │
│                                                               │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  Job 2: DEPLOY TO DEVELOPMENT (5-7 min)                      │
│  ════════════════════════════════════════                     │
│                                                               │
│  ┌────────────────────────────────────────┐                  │
│  │ 1. Setup Tools                         │                  │
│  │    - kubectl latest                    │                  │
│  │    - Helm v3.14.0                      │                  │
│  └────────────────────────────────────────┘                  │
│           ▼                                                   │
│  ┌────────────────────────────────────────┐                  │
│  │ 2. Configure Cluster Access            │                  │
│  │    echo $KUBECONFIG_DEV | base64 -d    │                  │
│  │    → ~/.kube/config                    │                  │
│  └────────────────────────────────────────┘                  │
│           ▼                                                   │
│  ┌────────────────────────────────────────┐                  │
│  │ 3. Prepare Namespace                   │                  │
│  │    kubectl create ns backstage         │                  │
│  └────────────────────────────────────────┘                  │
│           ▼                                                   │
│  ┌────────────────────────────────────────┐                  │
│  │ 4. Apply Secrets                       │                  │
│  │    kubectl create secret backstage...  │                  │
│  │    - POSTGRES_*                        │                  │
│  │    - GITHUB_TOKEN                      │                  │
│  │    - AUTH_GITHUB_*                     │                  │
│  │    - BACKEND_SECRET                    │                  │
│  │    - ARGOCD_*                          │                  │
│  └────────────────────────────────────────┘                  │
│           ▼                                                   │
│  ┌────────────────────────────────────────┐                  │
│  │ 5. Apply ConfigMap                     │                  │
│  │    kubectl apply -f kubernetes/        │                  │
│  │    configmap.yaml                      │                  │
│  └────────────────────────────────────────┘                  │
│           ▼                                                   │
│  ┌────────────────────────────────────────┐                  │
│  │ 6. Deploy with Helm                    │                  │
│  │    helm upgrade --install backstage \  │                  │
│  │      ./helm/backstage \                │                  │
│  │      --namespace backstage \           │                  │
│  │      --set image.tag=develop-sha \     │                  │
│  │      --wait --timeout 10m              │                  │
│  └────────────────────────────────────────┘                  │
│           ▼                                                   │
│  ┌────────────────────────────────────────┐                  │
│  │ 7. Verify Deployment                   │                  │
│  │    kubectl rollout status...           │                  │
│  │    kubectl get pods -n backstage       │                  │
│  └────────────────────────────────────────┘                  │
│                                                               │
│  ✅ Development Deployment Complete                           │
│  🌐 http://backstage.kind.local                              │
│                                                               │
└───────────────────────────────────────────────────────────────┘
         │
         │ 🧪 QA Testing & Approval
         ▼
┌─────────────────────────────────────────────────────────────┐
│                   PRODUCTION DEPLOYMENT                      │
└─────────────────────────────────────────────────────────────┘

Create PR: develop → main
         │
         │ 👍 Approve & Merge
         ▼
┌───────────────────────────────────────────────────────────────┐
│  🚀 GitHub Actions: Production Deploy                        │
│     Trigger: push to main                                     │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  Job 1: BUILD (6-8 min)                                       │
│  ════════════════════                                         │
│  (Same as Development)                                        │
│                                                               │
│  📦 Tags: latest, main-abc1234                                │
│                                                               │
├───────────────────────────────────────────────────────────────┤
│                                                               │
│  Job 2: DEPLOY TO PRODUCTION (8-10 min)                      │
│  ═══════════════════════════════════════                      │
│                                                               │
│  Similar to Development, but with:                            │
│  ├─ KUBECONFIG_PROD                                          │
│  ├─ Production secrets (*_PROD)                              │
│  ├─ TLS enabled                                              │
│  ├─ Domain: backstage.arhean.com                             │
│  └─ Smoke tests                                              │
│                                                               │
│  ✅ Production Deployment Complete                            │
│  🌐 https://backstage.arhean.com                             │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

---

## 🎯 Comandos Importantes

### Local Development

```bash
# Build and test locally
make build                  # Build backend + frontend
make build-docker          # Build Docker image
make kind-load             # Load image to Kind cluster
make restart               # Restart deployment

# Quick deploy (no Docker Hub push)
make quick-deploy          # Build + restart

# Full workflow with Helm
make helm-upgrade          # Build + Helm upgrade
```

### Monitoring GitHub Actions

```bash
# Ver workflows
gh workflow list

# Ver runs activos
gh run list --limit 5

# Ver logs de último run
gh run view --log

# Ver logs de job específico
gh run view <run-id> --log --job <job-id>

# Watch run en tiempo real
gh run watch
```

### Kubernetes Monitoring

```bash
# Watch pods durante deploy
kubectl get pods -n backstage -w

# Ver logs en tiempo real
kubectl logs -f deployment/backstage -n backstage

# Ver eventos
kubectl get events -n backstage --watch --sort-by='.lastTimestamp'

# Verificar health
kubectl describe deployment backstage -n backstage
```

---

## 🔄 Rollback Strategies

### 1. Helm Rollback (Recomendado)

```bash
# Ver historial de releases
helm history backstage -n backstage

REVISION  UPDATED                   STATUS      CHART           APP VERSION
1         Mon Oct 10 10:00:00 2025  superseded  backstage-1.0.0 1.0.0
2         Mon Oct 10 12:00:00 2025  superseded  backstage-1.0.0 1.0.0
3         Mon Oct 10 14:00:00 2025  deployed    backstage-1.0.0 1.0.0

# Rollback a versión anterior
helm rollback backstage -n backstage

# Rollback a revisión específica
helm rollback backstage 2 -n backstage
```

### 2. Git Revert

```bash
# Revertir commit problemático
git revert <commit-hash>
git push origin main

# GitHub Actions automáticamente deploya versión anterior
```

### 3. Manual Emergency

```bash
# Usar imagen conocida anterior
kubectl set image deployment/backstage \
  backstage=jaimehenao8126/backstage-production:previous-working-tag \
  -n backstage

# Verificar
kubectl rollout status deployment/backstage -n backstage
```

---

## 📈 Métricas y Tiempos

| Etapa | Tiempo Estimado |
|-------|----------------|
| PR Checks | 5-10 min |
| Build Job | 6-8 min |
| Deploy Dev | 5-7 min |
| Deploy Prod | 8-10 min |
| **Total (PR → Prod)** | **25-35 min** |

### Optimizaciones

- ✅ Cache de Docker layers
- ✅ Cache de Node modules
- ✅ Builds paralelos
- ✅ Incremental builds

---

## 🚨 Troubleshooting

### Build falla

```bash
# Reproducir localmente
cd backstage-kind
yarn install
yarn workspace backend build
yarn workspace app build
```

### Deploy falla

```bash
# Verificar secrets
kubectl get secret backstage-secrets -n backstage -o yaml

# Verificar ConfigMap
kubectl get configmap backstage-env-config -n backstage -o yaml

# Ver logs de pod fallido
kubectl logs <pod-name> -n backstage --previous
```

### Imagen no se actualiza

```bash
# Forzar pull de nueva imagen
kubectl delete pod -n backstage -l app=backstage

# Verificar image pull policy
kubectl get deployment backstage -n backstage -o yaml | grep imagePullPolicy
```

---

## 📚 Recursos

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Makefile Tutorial](https://makefiletutorial.com/)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)

---

## ✅ Checklist Pre-Deploy

- [ ] GitHub Secrets configurados
- [ ] Branches `develop` y `main` creados
- [ ] Workflows committed
- [ ] Helm chart validado (`helm lint`)
- [ ] Docker Hub credentials válidos
- [ ] Kubeconfig válido y codificado
- [ ] ConfigMap y Secrets aplicados
- [ ] Test local exitoso
- [ ] PR Checks pasando

---

**🎉 Una vez completado, cada push iniciará el pipeline automáticamente!**

**Última actualización:** Octubre 10, 2025
