# 🔐 ArgoCD Configuration - Complete Guide

**Fecha:** Octubre 11, 2025
**Proyecto:** Backstage Kind Migration with GitOps
**Maintainer:** Jaime Henao <jaime.andres.henao.arbelaez@ba.com>

---

## 📋 Índice

1. [Configuración Actual](#configuración-actual)
2. [GitHub OAuth](#github-oauth)
3. [RBAC y Permisos](#rbac-y-permisos)
4. [Secrets y Credenciales](#secrets-y-credenciales)
5. [Acceso](#acceso)
6. [Comandos Útiles](#comandos-útiles)

---

## ⚙️ Configuración Actual

### ArgoCD Version
- **Version**: v3.1.5
- **Namespace**: `argocd`
- **URL**: https://argocd.kind.local

### Componentes Desplegados

```bash
# Pods en namespace argocd
argocd-application-controller-0      # Application controller (StatefulSet)
argocd-applicationset-controller     # ApplicationSet controller
argocd-dex-server                    # OAuth/SSO provider (Dex)
argocd-image-updater                 # Image updater for GitOps
argocd-notifications-controller      # Notifications controller
argocd-redis                         # Redis for caching
argocd-repo-server                   # Git repository server
argocd-server                        # API and UI server
```

---

## 🔐 GitHub OAuth

### OAuth Application

**Detalles de la aplicación:**
- **Name**: ArgoCD Backstage Local
- **Client ID**: `Ov23liX98Qe1ectC1zdj`
- **Client Secret**: Almacenado en `argocd-secret`
- **Homepage URL**: `https://argocd.kind.local`
- **Callback URL**: `https://argocd.kind.local/api/dex/callback`

### Configuración en ArgoCD

**ConfigMap**: `argocd-cm`

```yaml
dex.config: |
  connectors:
  - type: github
    id: github
    name: GitHub
    config:
      clientID: $dex.github.clientId
      clientSecret: $dex.github.clientSecret
      orgs:
      - name: Portfolio-jaime
      teamNameField: slug
      useLoginAsID: false
```

**Secret**: `argocd-secret`

```yaml
data:
  dex.github.clientId: <base64-encoded>
  dex.github.clientSecret: <base64-encoded>
```

### Recrear Secret (si es necesario)

```bash
# Desde .env
source .env

kubectl create secret generic argocd-secret-github \
  -n argocd \
  --from-literal=dex.github.clientId=$AUTH_GITHUB_CLIENT_ID \
  --from-literal=dex.github.clientSecret=$AUTH_GITHUB_CLIENT_SECRET \
  --dry-run=client -o yaml > argocd-github-oauth-secret.yaml

# Aplicar al secret existente
kubectl patch secret argocd-secret -n argocd --type='json' -p="[
  {\"op\": \"replace\", \"path\": \"/data/dex.github.clientId\", \"value\": \"$(echo -n $AUTH_GITHUB_CLIENT_ID | base64)\"},
  {\"op\": \"replace\", \"path\": \"/data/dex.github.clientSecret\", \"value\": \"$(echo -n $AUTH_GITHUB_CLIENT_SECRET | base64)\"}
]"

# Reiniciar Dex
kubectl rollout restart deployment argocd-dex-server -n argocd
```

---

## 👥 RBAC y Permisos

### Configuración Actual

**ConfigMap**: `argocd-rbac-cm`

```yaml
data:
  policy.csv: |
    # Full admin access for all resources
    p, role:admin, *, *, *, allow

    # Assign admin role to specific GitHub user
    g, jaimehenao8126, role:admin

    # Also grant admin to entire Portfolio-jaime organization
    g, Portfolio-jaime:*, role:admin

  policy.default: role:readonly
  scopes: "[groups, email]"
```

### Permisos por Rol

#### role:admin (Administrador Completo)
- ✅ Crear/editar/eliminar Applications
- ✅ Crear/editar/eliminar Clusters
- ✅ Crear/editar/eliminar Repositories
- ✅ Gestionar Certificates
- ✅ Gestionar Accounts
- ✅ Gestionar GPG Keys
- ✅ Ver logs y eventos
- ✅ Ejecutar sync manual
- ✅ Ejecutar rollback
- ✅ Modificar RBAC

#### role:readonly (Solo Lectura)
- ✅ Ver Applications
- ✅ Ver Clusters
- ✅ Ver Repositories
- ❌ No puede modificar nada

### Usuarios Configurados

| Usuario | Rol | Acceso |
|---------|-----|--------|
| `admin` (local) | Superadmin | Acceso completo siempre |
| `jaimehenao8126` (GitHub) | Admin | Acceso completo via GitHub OAuth |
| `Portfolio-jaime:*` (GitHub Org) | Admin | Todos los miembros de la org tienen admin |
| Otros usuarios autenticados | Readonly | Solo lectura |

### Actualizar RBAC

```bash
# Editar ConfigMap
kubectl edit configmap argocd-rbac-cm -n argocd

# O aplicar patch
kubectl patch configmap argocd-rbac-cm -n argocd --type merge -p '
{
  "data": {
    "policy.csv": "p, role:admin, *, *, *, allow\ng, jaimehenao8126, role:admin"
  }
}'

# Reiniciar server para aplicar cambios
kubectl rollout restart deployment argocd-server -n argocd
```

### Verificar Permisos

```bash
# Ver configuración actual
kubectl get configmap argocd-rbac-cm -n argocd -o yaml

# Verificar permisos de un usuario (requiere argocd CLI)
argocd account can-i sync applications '*'
argocd account can-i create applications '*'
```

---

## 🔑 Secrets y Credenciales

### 1. argocd-secret (Principal)

Contiene credenciales sensibles:

```yaml
data:
  admin.password: <bcrypt-hash>
  admin.passwordMtime: <timestamp>
  server.secretkey: <secret-key>
  dex.github.clientId: <base64>
  dex.github.clientSecret: <base64>
```

### 2. github-repo-creds (Git Authentication)

Para write-back de ArgoCD Image Updater:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: github-repo-creds
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: https://github.com/Portfolio-jaime/BACKSTAGE-KIND-MIGRATION.git
  username: Portfolio-jaime
  password: ${GITHUB_TOKEN}
```

**Crear secret:**

```bash
source .env

cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: github-repo-creds
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  type: git
  url: https://github.com/Portfolio-jaime/BACKSTAGE-KIND-MIGRATION.git
  username: Portfolio-jaime
  password: $GITHUB_TOKEN
EOF
```

### 3. dockerhub-secret (Docker Hub)

Para ArgoCD Image Updater:

```bash
source .env

kubectl create secret generic dockerhub-secret \
  --from-literal=username=$DOCKERHUB_USERNAME \
  --from-literal=password=$DOCKERHUB_TOKEN \
  --namespace=argocd \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 4. argocd-initial-admin-secret

Secret temporal con password de admin:

```bash
# Obtener password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Eliminar después de cambiar password
kubectl delete secret argocd-initial-admin-secret -n argocd
```

---

## 🌐 Acceso

### Método 1: Ingress (Recomendado)

**URL**: https://argocd.kind.local

**Requisitos:**
1. Agregar a `/etc/hosts`:
   ```bash
   echo "127.0.0.1 argocd.kind.local" | sudo tee -a /etc/hosts
   ```

2. Ingress debe estar configurado:
   ```bash
   kubectl get ingress -n argocd
   ```

**Login:**
- Click en **"LOG IN VIA GITHUB"** ✅
- O usar credenciales locales:
  - Usuario: `admin`
  - Password: Ver comando abajo

### Método 2: Port Forward

```bash
# Terminal 1: Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Terminal 2: Abrir navegador
open https://localhost:8080
```

### Obtener Password de Admin Local

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

### Cambiar Password de Admin

```bash
# Con argocd CLI
argocd login localhost:8080
argocd account update-password

# O desde UI
# Settings > Accounts > admin > Update Password
```

---

## 🛠️ Comandos Útiles

### Estado de Componentes

```bash
# Ver todos los pods
kubectl get pods -n argocd

# Ver Applications
kubectl get application -n argocd

# Ver estado detallado
kubectl describe application backstage -n argocd
```

### Logs

```bash
# Logs de ArgoCD Server
kubectl logs -n argocd deployment/argocd-server -f

# Logs de Dex (OAuth)
kubectl logs -n argocd deployment/argocd-dex-server -f

# Logs de Image Updater
kubectl logs -n argocd deployment/argocd-image-updater -f

# Logs de Application Controller
kubectl logs -n argocd statefulset/argocd-application-controller -f
```

### Reiniciar Componentes

```bash
# Reiniciar servidor (después de cambios en RBAC o CM)
kubectl rollout restart deployment argocd-server -n argocd

# Reiniciar Dex (después de cambios en OAuth)
kubectl rollout restart deployment argocd-dex-server -n argocd

# Reiniciar todos los componentes
kubectl rollout restart -n argocd \
  deployment/argocd-server \
  deployment/argocd-dex-server \
  deployment/argocd-repo-server \
  deployment/argocd-redis \
  deployment/argocd-applicationset-controller \
  deployment/argocd-notifications-controller
```

### Verificar Configuración

```bash
# Ver ConfigMap de ArgoCD
kubectl get configmap argocd-cm -n argocd -o yaml

# Ver RBAC ConfigMap
kubectl get configmap argocd-rbac-cm -n argocd -o yaml

# Ver secrets (sin valores)
kubectl get secret -n argocd

# Ver secret específico (base64 encoded)
kubectl get secret argocd-secret -n argocd -o yaml
```

### ArgoCD CLI

```bash
# Install CLI (macOS)
brew install argocd

# Login
argocd login localhost:8080

# Ver applications
argocd app list

# Ver detalles de una app
argocd app get backstage

# Sync manual
argocd app sync backstage

# Ver logs
argocd app logs backstage -f

# Ver diff
argocd app diff backstage
```

---

## 🔄 Backup y Restore

### Backup de Configuración

```bash
# Exportar todas las Applications
kubectl get applications -n argocd -o yaml > argocd-applications-backup.yaml

# Exportar todos los ConfigMaps
kubectl get configmap -n argocd -o yaml > argocd-configmaps-backup.yaml

# Exportar secrets (SIN valores sensibles para Git)
kubectl get secret -n argocd \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' \
  > argocd-secrets-list.txt
```

### Restore

```bash
# Aplicar Applications
kubectl apply -f argocd-applications-backup.yaml

# Recrear secrets manualmente desde .env
source .env
# ... crear secrets con comandos de arriba
```

---

## 🚨 Troubleshooting

### GitHub OAuth no funciona

```bash
# 1. Verificar configuración de Dex
kubectl logs -n argocd deployment/argocd-dex-server --tail=50

# 2. Verificar secret tiene credenciales
kubectl get secret argocd-secret -n argocd -o jsonpath='{.data.dex\.github\.clientId}' | base64 -d
kubectl get secret argocd-secret -n argocd -o jsonpath='{.data.dex\.github\.clientSecret}' | base64 -d

# 3. Verificar callback URL en GitHub OAuth App
# Debe ser: https://argocd.kind.local/api/dex/callback

# 4. Reiniciar Dex
kubectl rollout restart deployment argocd-dex-server -n argocd
```

### No tengo permisos después de login

```bash
# 1. Verificar RBAC
kubectl get configmap argocd-rbac-cm -n argocd -o yaml

# 2. Verificar tu usuario en logs
kubectl logs -n argocd deployment/argocd-server | grep "preferred_username"

# 3. Actualizar RBAC con tu usuario
kubectl patch configmap argocd-rbac-cm -n argocd --type merge -p '
{
  "data": {
    "policy.csv": "p, role:admin, *, *, *, allow\ng, TU_USUARIO, role:admin"
  }
}'

# 4. Reiniciar server
kubectl rollout restart deployment argocd-server -n argocd
```

### Image Updater no actualiza

```bash
# Ver logs de Image Updater
kubectl logs -n argocd deployment/argocd-image-updater -f

# Verificar annotations en Application
kubectl get application backstage -n argocd -o yaml | grep image-updater

# Force update (recrear pod)
kubectl delete pod -n argocd -l app.kubernetes.io/name=argocd-image-updater
```

---

## 📚 Referencias

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD RBAC](https://argo-cd.readthedocs.io/en/stable/operator-manual/rbac/)
- [Dex GitHub Connector](https://dexidp.io/docs/connectors/github/)
- [ArgoCD Image Updater](https://argocd-image-updater.readthedocs.io/)

---

**Última actualización:** Octubre 11, 2025
**Maintainer:** Jaime Henao <jaime.andres.henao.arbelaez@ba.com>
**Status:** ✅ Completamente configurado y funcional
