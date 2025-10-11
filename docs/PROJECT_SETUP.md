# 🚀 Backstage Kind Migration - Guía de Configuración del Proyecto

## 📋 Índice

1. [Visión General](#visión-general)
2. [Arquitectura](#arquitectura)
3. [Configuración Inicial](#configuración-inicial)
4. [CI/CD con GitHub Actions](#cicd-con-github-actions)
5. [GitOps con ArgoCD](#gitops-con-argocd)
6. [Monitoreo](#monitoreo)
7. [Comandos Útiles](#comandos-útiles)

## 🎯 Visión General

Este proyecto implementa Backstage en un cluster de Kubernetes (Kind) local con:

- **GitOps**: ArgoCD gestiona todos los deployments
- **CI/CD**: GitHub Actions construye y publica imágenes Docker
- **Monitoreo**: Prometheus + Grafana
- **Gestión de Secrets**: Kubernetes Secrets + GitHub Secrets
- **Base de Datos**: PostgreSQL en el cluster

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                     FLUJO COMPLETO                          │
└─────────────────────────────────────────────────────────────┘

Developer
    │
    ├─> git push
    │
    ▼
GitHub Repository
    │
    ├─> Trigger GitHub Actions
    │
    ▼
GitHub Actions Workflow
    │
    ├─> Build & Test
    ├─> Build Docker Image
    └─> Push to Docker Hub
            │
            ▼
    Docker Hub: jaimehenao8126/backstage-production:latest
            │
            ▼
    ArgoCD Image Updater (cada 2 min)
            │
            ├─> Detecta nueva imagen
            ├─> Actualiza helm/backstage/values.yaml
            └─> Commit a Git
                    │
                    ▼
            ArgoCD (auto-sync)
                    │
                    ├─> Detecta cambio en Git
                    ├─> Helm upgrade
                    └─> Rolling update
                            │
                            ▼
                    Kubernetes Cluster (Kind)
                            │
                            ├─> Backstage Pod
                            ├─> PostgreSQL
                            └─> Prometheus + Grafana
```

## ⚙️ Configuración Inicial

### 1. Prerrequisitos

```bash
# Instalar herramientas necesarias
- Docker Desktop
- Kind (Kubernetes in Docker)
- kubectl
- Helm
- Node.js 20+
- Yarn
```

### 2. Crear Cluster Kind

```bash
make kind-create
```

### 3. Variables de Entorno

Crear archivo `.env` en la raíz del proyecto:

```bash
# PostgreSQL
POSTGRES_HOST=psql-postgresql.backstage.svc.cluster.local
POSTGRES_PORT=5432
POSTGRES_USER=backstage
POSTGRES_PASSWORD=your-password
POSTGRES_DB=backstage

# GitHub
GITHUB_TOKEN=ghp_xxxxxxxxxxxxx

# ArgoCD
ARGOCD_USERNAME=admin
ARGOCD_PASSWORD=your-password

# Docker Hub
DOCKERHUB_USERNAME=your-username
DOCKERHUB_TOKEN=dckr_pat_xxxxxxxxxxxxx

# Backend
BACKEND_SECRET=your-secret-key

# GitHub OAuth (opcional)
AUTH_GITHUB_CLIENT_ID=your-client-id
AUTH_GITHUB_CLIENT_SECRET=your-client-secret
```

### 4. Desplegar PostgreSQL

```bash
make deploy-postgres
```

### 5. Crear Secrets en Kubernetes

```bash
make create-secrets
```

### 6. Instalar ArgoCD

```bash
chmod +x scripts/setup-argocd.sh
./scripts/setup-argocd.sh
```

## 🔄 CI/CD con GitHub Actions

### Configuración de GitHub Secrets

Sube los secrets a GitHub:

```bash
chmod +x scripts/upload-secrets.sh
./scripts/upload-secrets.sh
```

### Workflow Automático

El workflow `.github/workflows/ci-cd.yaml` se ejecuta automáticamente cuando:

- Haces push a `main` o `develop`
- Modificas archivos en: `backstage-kind/`, `helm/`, `kubernetes/`

**Pasos del workflow:**
1. ✅ Build & Test del código
2. 🐳 Build de imagen Docker
3. 📤 Push a Docker Hub
4. 📝 Notificación de deployment disponible

## 🎯 GitOps con ArgoCD

### Acceso a ArgoCD UI

```bash
# Terminal 1: Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Terminal 2: Obtener password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

**Acceso:**
- URL: https://localhost:8080
- Username: `admin`
- Password: (output del comando anterior)

### Sincronización Automática

ArgoCD está configurado con:

- **Auto-sync**: Aplica cambios automáticamente cuando detecta diferencias en Git
- **Self-heal**: Corrige automáticamente drift en el cluster
- **Prune**: Elimina recursos huérfanos automáticamente

### Image Updater

ArgoCD Image Updater monitorea Docker Hub cada 2 minutos:

1. 🔍 Detecta nueva imagen en `jaimehenao8126/backstage-production:latest`
2. 📝 Actualiza `helm/backstage/values.yaml` en Git
3. 💾 Hace commit automático
4. 🔄 ArgoCD sincroniza el cambio

**Ver logs del Image Updater:**
```bash
kubectl logs -n argocd deployment/argocd-image-updater -f
```

## 📊 Monitoreo

### Prometheus + Grafana

```bash
# Desplegar stack de monitoreo
make deploy-monitoring

# Acceder a Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Credenciales por defecto
Usuario: admin
Password: prom-operator
```

### Métricas Disponibles

- **Backstage**: CPU, memoria, requests, latencia
- **PostgreSQL**: Conexiones, queries, performance
- **Kubernetes**: Pods, nodes, recursos
- **ArgoCD**: Sync status, health status

## 🛠️ Comandos Útiles

### Gestión del Cluster

```bash
# Ver todo en el namespace backstage
kubectl get all -n backstage

# Ver estado de ArgoCD Applications
kubectl get application -n argocd

# Ver logs de Backstage
kubectl logs -n backstage -l app=backstage -f

# Reiniciar Backstage
kubectl rollout restart deployment/backstage -n backstage
```

### Desarrollo Local

```bash
# Build de imagen Docker local
make build-docker

# Load imagen en Kind
make load-image

# Deploy con Helm
make helm-install

# Upgrade con Helm
make helm-upgrade
```

### Acceso a Servicios

```bash
# Backstage
kubectl port-forward -n backstage svc/backstage 7007:80

# PostgreSQL
kubectl port-forward -n backstage svc/psql-postgresql 5432:5432

# ArgoCD
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

### Troubleshooting

```bash
# Ver eventos del cluster
kubectl get events -n backstage --sort-by='.lastTimestamp'

# Describir pod con problemas
kubectl describe pod -n backstage <pod-name>

# Ver logs de init containers
kubectl logs -n backstage <pod-name> -c wait-for-postgres

# Verificar secrets
kubectl get secret backstage-secrets -n backstage -o yaml

# Ver Application details en ArgoCD
kubectl describe application backstage -n argocd
```

## 📁 Estructura del Proyecto

```
backstage-kind-migration/
├── .github/
│   └── workflows/
│       └── ci-cd.yaml              # CI/CD pipeline
│
├── argocd/
│   ├── backstage-application.yaml  # ArgoCD Application
│   ├── image-updater-config.yaml   # Image Updater config
│   └── github-repo-secret.yaml     # GitHub credentials (template)
│
├── backstage-kind/                 # Código fuente de Backstage
│   ├── packages/
│   │   ├── app/                    # Frontend
│   │   └── backend/                # Backend
│   ├── app-config.yaml             # Configuración
│   └── Dockerfile.kind             # Dockerfile optimizado
│
├── helm/
│   └── backstage/
│       ├── Chart.yaml              # Helm chart
│       ├── values.yaml             # Valores por defecto
│       └── templates/              # Kubernetes manifests
│
├── kubernetes/
│   ├── namespace.yaml              # Namespace definition
│   ├── secrets.yaml.template       # Template de secrets
│   └── configmap.yaml              # ConfigMaps
│
├── scripts/
│   ├── setup-argocd.sh            # Setup de ArgoCD
│   └── upload-secrets.sh          # Upload de GitHub Secrets
│
├── docs/                          # Documentación
│   ├── PROJECT_SETUP.md           # Esta guía
│   ├── GITOPS_ARGOCD.md          # GitOps detallado
│   └── ARCHITECTURE_DIAGRAMS.md   # Diagramas
│
├── Makefile                       # Comandos útiles
└── README.md                      # Inicio rápido
```

## 🔐 Seguridad

### GitHub Secrets

Todos los secrets sensibles están en GitHub Secrets:
- `DOCKERHUB_USERNAME` y `DOCKERHUB_TOKEN`
- `POSTGRES_*` variables
- `GITHUB_TOKEN`
- `ARGOCD_*` credentials

### Kubernetes Secrets

Los secrets en el cluster NO están en Git:
- `backstage-secrets`: Credenciales de la aplicación
- `github-repo-creds`: Credenciales de ArgoCD para GitHub
- `dockerhub-secret`: Credenciales para pull de imágenes

### Best Practices

1. ✅ Nunca commitear `.env` a Git (está en `.gitignore`)
2. ✅ Rotar secrets regularmente
3. ✅ Usar GitHub Secrets para CI/CD
4. ✅ Usar Kubernetes Secrets para runtime
5. ✅ Considerar Sealed Secrets o External Secrets Operator para producción

## 🚀 Flujo de Trabajo Diario

### Desarrollar nueva feature

```bash
# 1. Crear branch
git checkout -b feature/mi-feature

# 2. Hacer cambios en backstage-kind/

# 3. Commit y push
git add .
git commit -m "feat: mi nueva feature"
git push origin feature/mi-feature

# 4. Crear PR a main

# 5. Una vez mergeado:
#    - GitHub Actions construye imagen
#    - Push a Docker Hub
#    - ArgoCD Image Updater detecta cambio
#    - ArgoCD aplica cambios automáticamente
```

### Verificar deployment

```bash
# 1. Ver estado en ArgoCD UI
# https://localhost:8080

# 2. O por CLI
kubectl get application backstage -n argocd

# 3. Verificar pod
kubectl get pods -n backstage

# 4. Ver logs
kubectl logs -n backstage -l app=backstage -f

# 5. Probar aplicación
kubectl port-forward -n backstage svc/backstage 7007:80
# Abrir http://localhost:7007
```

## 📚 Referencias

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Backstage Documentation](https://backstage.io/docs)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GitHub Actions Documentation](https://docs.github.com/actions)

## 🤝 Contribuir

Para contribuir al proyecto:

1. Fork del repositorio
2. Crear branch de feature
3. Hacer cambios y commit
4. Push y crear Pull Request
5. Esperar revisión y merge

---

**Última actualización**: Octubre 11, 2025
**Maintainer**: Jaime Henao <jaime.andres.henao.arbelaez@ba.com>
