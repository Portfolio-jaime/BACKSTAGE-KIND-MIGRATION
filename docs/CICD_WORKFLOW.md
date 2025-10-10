# 🚀 CI/CD Workflow - Proceso Completo

## 📋 Flujo de Trabajo Completo

### 🎯 Escenario: Desarrollador hace un cambio

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEVELOPER WORKFLOW                            │
└─────────────────────────────────────────────────────────────────┘

1. Developer Local Machine
   ├── Crear feature branch
   │   $ git checkout -b feature/add-github-auth
   │
   ├── Hacer cambios en código
   │   - Editar backstage-kind/app-config.yaml
   │   - Editar backstage-kind/packages/backend/src/...
   │
   ├── Probar localmente
   │   $ make build
   │   $ make build-docker
   │   $ make kind-load
   │   $ make restart
   │
   └── Push y crear PR
       $ git add .
       $ git commit -m "feat: add GitHub authentication"
       $ git push origin feature/add-github-auth
       → Crear Pull Request en GitHub
```

---

## 🔄 CI/CD Pipeline Automático

### **Paso 1: Pull Request Creado**

Cuando creas un PR, se activa `.github/workflows/pr-checks.yaml`

```yaml
┌────────────────────────────────────────────┐
│     GitHub Actions: PR Checks              │
├────────────────────────────────────────────┤
│                                            │
│  Job 1: Lint and Test                     │
│    ✓ Checkout code                        │
│    ✓ Setup Node.js 20                     │
│    ✓ Install dependencies (yarn)          │
│    ✓ Run backend lint                     │
│    ✓ Run frontend lint                    │
│    ✓ Run backend tests                    │
│    ✓ Run frontend tests                   │
│                                            │
│  Job 2: Build Check                       │
│    ✓ Build backend (yarn build)           │
│    ✓ Build frontend (yarn build)          │
│                                            │
│  Job 3: Helm Lint                         │
│    ✓ Lint Helm chart                      │
│    ✓ Template Helm chart                  │
│                                            │
│  Job 4: Docker Build Test                 │
│    ✓ Build Docker image (no push)         │
│    ✓ Validate Dockerfile                  │
│                                            │
└────────────────────────────────────────────┘

✅ Todos los checks pasan → Listo para merge
❌ Algún check falla → Revisar errores
```

**Tiempo estimado:** 5-10 minutos

---

### **Paso 2: Merge a `develop` Branch**

Cuando haces merge del PR a `develop`, se activa `.github/workflows/ci-cd.yaml`

```yaml
┌────────────────────────────────────────────┐
│   GitHub Actions: CI/CD Pipeline           │
│   Triggered: Push to develop               │
├────────────────────────────────────────────┤
│                                            │
│  Job 1: Build (Siempre se ejecuta)        │
│  ─────────────────────────────────────     │
│    ✓ Checkout code                        │
│    ✓ Setup Node.js 20                     │
│    ✓ Install dependencies                 │
│    ✓ Run linter                           │
│    ✓ Run tests                            │
│    ✓ Build backend                        │
│    ✓ Build frontend                       │
│    ✓ Login to Docker Hub                  │
│    ✓ Build Docker image                   │
│    ✓ Tag: develop-<sha>                   │
│    ✓ Push to Docker Hub                   │
│                                            │
│  Job 2: Deploy to Development             │
│  ─────────────────────────────────────     │
│    ✓ Checkout code                        │
│    ✓ Setup kubectl + Helm                 │
│    ✓ Configure kubeconfig (from secret)   │
│    ✓ Create namespace                     │
│    ✓ Apply secrets (from GitHub secrets)  │
│    ✓ Apply ConfigMap                      │
│    ✓ Deploy with Helm:                    │
│        $ helm upgrade --install backstage \
│            ./helm/backstage \              │
│            --namespace backstage \         │
│            --set image.tag=<sha>          │
│    ✓ Verify deployment                    │
│                                            │
└────────────────────────────────────────────┘

✅ Deployment to Development Success
📊 View at: http://backstage.kind.local
```

**Tiempo estimado:** 10-15 minutos

---

### **Paso 3: Merge a `main` Branch (Production)**

Cuando haces merge de `develop` a `main`, se despliega a producción

```yaml
┌────────────────────────────────────────────┐
│   GitHub Actions: Production Deploy        │
│   Triggered: Push to main                  │
├────────────────────────────────────────────┤
│                                            │
│  Job 1: Build                              │
│  ─────────────────────────────────────     │
│    (Mismo proceso que develop)            │
│    ✓ Tag: latest, main-<sha>             │
│    ✓ Push to Docker Hub                   │
│                                            │
│  Job 2: Deploy to Production               │
│  ─────────────────────────────────────     │
│    ✓ Setup kubectl + Helm                 │
│    ✓ Configure PROD kubeconfig            │
│    ✓ Apply PROD secrets                   │
│    ✓ Deploy with Helm:                    │
│        $ helm upgrade --install backstage \
│            ./helm/backstage \              │
│            --namespace backstage \         │
│            --set image.tag=<sha> \        │
│            --set ingress.host=backstage.arhean.com \
│            --set ingress.tls.enabled=true │
│    ✓ Verify deployment                    │
│    ✓ Run smoke tests                      │
│                                            │
└────────────────────────────────────────────┘

✅ Production Deployment Success
🌐 View at: https://backstage.arhean.com
```

**Tiempo estimado:** 10-15 minutos

---

## 🎬 Ejemplo Paso a Paso Real

### **Día 1: Feature Development**

```bash
# 9:00 AM - Developer empieza
git checkout -b feature/fix-auth-bug
code backstage-kind/app-config.yaml  # Hacer cambios

# 10:00 AM - Test local
make build
make build-docker
make kind-load
make restart

# 10:30 AM - Verificar en http://backstage.kind.local
# ✅ Funciona!

# 11:00 AM - Commit y push
git add .
git commit -m "fix: remove guest auth, enable GitHub OAuth"
git push origin feature/fix-auth-bug

# 11:05 AM - Crear PR en GitHub
# → Ir a: https://github.com/your-user/backstage-kind-migration/pulls
# → Click "New Pull Request"
# → Base: develop ← Compare: feature/fix-auth-bug
```

### **11:05 AM - GitHub Actions: PR Checks**

```
⏳ Running PR Checks...
├─ ✅ Lint and Test (2 min)
├─ ✅ Build Check (3 min)
├─ ✅ Helm Lint (1 min)
└─ ✅ Docker Build Test (4 min)

✅ All checks passed! Ready to merge
```

### **11:15 AM - Code Review**

```
👀 Team Lead reviews PR
💬 "Looks good! LGTM 👍"
✅ Approve PR
🔀 Merge to develop
```

### **11:20 AM - GitHub Actions: Deploy to Dev**

```
🚀 Deploying to Development...
├─ ⏳ Build Job (6 min)
│   ├─ ✅ Tests passed
│   ├─ ✅ Docker image built
│   └─ ✅ Pushed: develop-abc1234
│
└─ ⏳ Deploy Job (8 min)
    ├─ ✅ Helm upgraded
    ├─ ✅ Pods running
    └─ ✅ Health check passed

✅ Deployment to Development Complete!
📊 http://backstage.kind.local
```

### **11:35 AM - QA Testing**

```
🧪 QA Team tests in Development
✅ GitHub auth works
✅ No guest login
✅ All features working
```

### **2:00 PM - Merge to Production**

```
# Create PR: develop → main
# Review and approve
# Merge to main
```

### **2:05 PM - GitHub Actions: Deploy to Prod**

```
🚀 Deploying to Production...
├─ ⏳ Build Job (6 min)
│   ├─ ✅ Docker image: main-abc1234, latest
│   └─ ✅ Pushed to Docker Hub
│
└─ ⏳ Deploy Job (10 min)
    ├─ ✅ Helm upgraded (PROD cluster)
    ├─ ✅ TLS enabled
    ├─ ✅ Pods healthy
    └─ ✅ Smoke tests passed

✅ Production Deployment Complete!
🌐 https://backstage.arhean.com
```

---

## 📊 Monitoreo Durante Deployment

### Ver logs en GitHub Actions

```
1. Ir a: https://github.com/your-user/backstage-kind-migration/actions
2. Click en el workflow run más reciente
3. Ver jobs en tiempo real:
   ├─ Build: logs de compilación
   └─ Deploy: logs de Helm/kubectl
```

### Monitorear Kubernetes

```bash
# En otra terminal, watch pods
kubectl get pods -n backstage -w

# Ver logs en tiempo real
kubectl logs -f deployment/backstage -n backstage

# Ver eventos
kubectl get events -n backstage --watch
```

---

## 🔄 Rollback Procedure

### Si algo sale mal en Production:

**Opción 1: Helm Rollback (Rápido)**

```bash
# Ver historial
helm history backstage -n backstage

# Rollback a versión anterior
helm rollback backstage -n backstage

# O rollback a versión específica
helm rollback backstage 5 -n backstage
```

**Opción 2: Revertir en Git**

```bash
# Hacer revert del commit
git revert <commit-hash>
git push origin main

# GitHub Actions automáticamente deploya la versión anterior
```

**Opción 3: Manual (Emergency)**

```bash
# Usar imagen anterior conocida
kubectl set image deployment/backstage \
  backstage=jaimehenao8126/backstage-production:previous-tag \
  -n backstage
```

---

## 📈 Métricas y Notificaciones

### Agregar Slack Notifications (Opcional)

```yaml
# En .github/workflows/ci-cd.yaml
- name: Notify Slack
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
    text: |
      Deployment to ${{ env.ENVIRONMENT }} ${{ job.status }}
      Image: ${{ steps.meta.outputs.tags }}
```

### Email Notifications

GitHub Actions envía emails automáticamente cuando:
- ❌ Un workflow falla
- ✅ Un workflow se recupera después de fallar

---

## 🎯 Best Practices

### 1. **Branch Protection**

Configurar en GitHub:
```
Settings → Branches → Add rule
├─ Branch name pattern: main
├─ ✅ Require pull request reviews (1)
├─ ✅ Require status checks (PR Checks)
├─ ✅ Require branches up to date
└─ ✅ Include administrators
```

### 2. **Environment Protection**

Configurar en GitHub:
```
Settings → Environments → production
├─ ✅ Required reviewers (Team Lead)
├─ ⏰ Wait timer: 0 minutes
└─ 🔐 Environment secrets
```

### 3. **Semantic Versioning**

Usar commits semánticos:
```
feat: nueva funcionalidad
fix: corrección de bug
docs: cambios en documentación
chore: tareas de mantenimiento
refactor: refactorización de código
test: agregar tests
```

### 4. **Tags para Releases**

```bash
# Crear tag para release
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0

# GitHub Actions puede usar tags para versionar imágenes
```

---

## 🚨 Troubleshooting

### Pipeline falla en Build

```bash
# Reproducir localmente
cd backstage-kind
yarn install
yarn workspace backend build
yarn workspace app build

# Ver error exacto
```

### Pipeline falla en Docker Build

```bash
# Build local con logs
docker build -f Dockerfile.kind -t test:local .

# Ver error de layers
```

### Pipeline falla en Helm Deploy

```bash
# Revisar Helm chart
helm lint ./helm/backstage

# Template para ver YAML generado
helm template backstage ./helm/backstage \
  --namespace backstage \
  --set image.tag=test

# Verificar conexión a cluster
kubectl cluster-info
kubectl get nodes
```

### Secrets no disponibles

```bash
# Listar secrets (no muestra valores)
gh secret list --repo your-user/backstage-kind-migration

# Actualizar secret
echo "new-value" | gh secret set SECRET_NAME --repo your-user/repo
```

---

## ✅ Checklist: Primera Ejecución

- [ ] GitHub Secrets configurados (use `./scripts/setup-github-secrets.sh`)
- [ ] Branch `develop` creado
- [ ] Branch `main` configurado como default
- [ ] Workflows en `.github/workflows/` committed
- [ ] Helm chart en `helm/backstage/` committed
- [ ] Kubeconfig de Development codificado en base64
- [ ] Docker Hub credentials válidos
- [ ] Test local con `make build-docker`
- [ ] Push a `develop` para probar pipeline
- [ ] Revisar logs en GitHub Actions

---

**📚 Referencias:**
- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Backstage Deployment](https://backstage.io/docs/deployment/)

---

**Última actualización:** Octubre 10, 2025
**Autor:** Jaime Henao
