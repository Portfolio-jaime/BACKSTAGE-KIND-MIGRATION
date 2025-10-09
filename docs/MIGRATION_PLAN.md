# 📋 Plan de Migración Detallado

**Estrategia**: Fresh Start - Crear nuevo proyecto Backstage optimizado para Kind desde cero

---

## 🎯 Objetivos

1. **Crear deployment limpio** sin legacy code del devcontainer
2. **Optimizar para producción** con best practices de Kubernetes
3. **Migrar solo configuraciones necesarias** del proyecto actual
4. **Implementar CI/CD ready** deployment

---

## 📊 Diferencias: Approach Anterior vs Fresh Start

| Aspecto | Approach Anterior | Fresh Start (Nuevo) |
|---------|------------------|---------------------|
| Código Base | Migrar devcontainer existente | Crear nuevo proyecto limpio |
| Complejidad | Alta (legacy + nuevas configs) | Media (solo lo necesario) |
| Deuda Técnica | Mantiene deuda del devcontainer | Cero deuda técnica |
| Optimización | Parcial | Total |
| Tiempo Setup | 8-11 horas | 4-6 horas |
| Testing | Más difícil (configs mezcladas) | Más fácil (configs claras) |
| Mantenibilidad | Media | Alta |

---

## 🔄 Flujo de Migración

### FASE 1: Auditoría (30 min)
**Objetivo**: Identificar qué migrar del proyecto actual

#### 1.1 Configuraciones a Migrar
- [ ] `app-config.yaml` - Configuración base
- [ ] Integraciones:
  - GitHub token y org
  - ArgoCD credentials y URL
  - Kubernetes cluster config
  - Prometheus/Grafana endpoints
- [ ] Catalog entities:
  - `catalog/entities/users.yaml`
  - `catalog/entities/groups.yaml`
  - `catalog/entities/systems.yaml`
  - `catalog/entities/monitoring-components.yaml`

#### 1.2 Plugins a Instalar
**Frontend** (`packages/app/package.json`):
```json
{
  "@backstage/plugin-kubernetes": "^0.12.11",
  "@roadiehq/backstage-plugin-argo-cd": "^2.11.0",
  "@backstage/plugin-home": "^0.8.11",
  "@backstage/plugin-techdocs": "^1.13.2",
  "@backstage/plugin-github-actions": "^0.6.16",
  "@backstage/plugin-todo": "^0.2.39",
  "@roadiehq/backstage-plugin-github-insights": "^3.2.0"
}
```

**Backend** (`packages/backend/package.json`):
```json
{
  "@backstage/plugin-kubernetes-backend": "^0.20.2",
  "@roadiehq/backstage-plugin-argo-cd-backend": "^4.4.1",
  "pg": "^8.11.3"
}
```

#### 1.3 Custom Components
- [ ] `packages/app/src/components/Root/Root.tsx` - Navigation customizada
- [ ] `packages/app/src/components/argocd/` - ArgoCD custom pages
- [ ] `packages/app/src/components/kubernetes/` - Kubernetes custom pages
- [ ] `packages/app/src/components/observability/` - Grafana/Prometheus pages

#### 1.4 NO Migrar (Fresh Start)
- ❌ `node_modules/` - Se reinstalará
- ❌ `.git/` - Nuevo repo
- ❌ `dist/`, `build/` - Se regenerará
- ❌ DevContainer configs - No necesario en Kind
- ❌ Docker compose - No necesario

---

### FASE 2: Setup Nuevo Proyecto (1 hora)

#### 2.1 Crear Nuevo Backstage
```bash
cd /Users/jaime.henao/arheanja/Backstage-solutions/backstage-kind-migration

# Crear nuevo proyecto
npx @backstage/create-app@latest --path backstage --skip-install

cd backstage

# Instalar dependencias
yarn install
```

#### 2.2 Instalar Plugins
```bash
# Frontend plugins
yarn workspace app add @backstage/plugin-kubernetes
yarn workspace app add @roadiehq/backstage-plugin-argo-cd
yarn workspace app add @backstage/plugin-home
yarn workspace app add @backstage/plugin-github-actions
yarn workspace app add @backstage/plugin-todo
yarn workspace app add @roadiehq/backstage-plugin-github-insights

# Backend plugins
yarn workspace backend add @backstage/plugin-kubernetes-backend
yarn workspace backend add @roadiehq/backstage-plugin-argo-cd-backend
yarn workspace backend add pg
```

#### 2.3 Configurar Database
**Archivo**: `backstage/app-config.yaml`
```yaml
backend:
  database:
    client: pg
    connection:
      host: ${POSTGRES_HOST}
      port: ${POSTGRES_PORT}
      user: ${POSTGRES_USER}
      password: ${POSTGRES_PASSWORD}
      database: ${POSTGRES_DB}
      ssl: false
```

---

### FASE 3: Migrar Configuraciones (1.5 horas)

#### 3.1 Copiar Configuraciones Básicas
```bash
# Desde proyecto actual
SOURCE=/Users/jaime.henao/arheanja/Backstage-solutions/backstage-app-devc/backstage
TARGET=/Users/jaime.henao/arheanja/Backstage-solutions/backstage-kind-migration/backstage

# Copiar catalog entities
cp -r $SOURCE/catalog/ $TARGET/

# Copiar custom components (revisar uno por uno)
cp -r $SOURCE/packages/app/src/components/argocd $TARGET/packages/app/src/components/
cp -r $SOURCE/packages/app/src/components/kubernetes $TARGET/packages/app/src/components/
cp -r $SOURCE/packages/app/src/components/observability $TARGET/packages/app/src/components/
```

#### 3.2 Configurar Integraciones
Editar `backstage/app-config.yaml`:

```yaml
# GitHub Integration
integrations:
  github:
    - host: github.com
      token: ${GITHUB_TOKEN}

# ArgoCD Integration
argocd:
  username: ${ARGOCD_USERNAME}
  password: ${ARGOCD_PASSWORD}
  appLocatorMethods:
    - type: 'config'
      instances:
        - name: argocd-main
          url: https://argocd.kind.local
          username: ${ARGOCD_USERNAME}
          password: ${ARGOCD_PASSWORD}

# Kubernetes Integration
kubernetes:
  serviceLocatorMethod:
    type: 'multiTenant'
  clusterLocatorMethods:
    - type: 'config'
      clusters:
        - url: https://kubernetes.default.svc
          name: kind-local
          authProvider: serviceAccount
          skipTLSVerify: true

# Grafana Integration
grafana:
  domain: http://grafana.kind.local
  unifiedAlerting: true

# Prometheus Integration
prometheus:
  proxyPath: /api/proxy/prometheus
```

#### 3.3 Configurar Catalog Locations
```yaml
catalog:
  locations:
    - type: file
      target: /app/catalog/entities/users.yaml
    - type: file
      target: /app/catalog/entities/groups.yaml
    - type: file
      target: /app/catalog/entities/systems.yaml
    - type: file
      target: /app/catalog/entities/monitoring-components.yaml
```

---

### FASE 4: Crear Configuración de Kubernetes (1 hora)

#### 4.1 Crear app-config.kubernetes.yaml
**Archivo**: `config/app-config.kubernetes.yaml`

```yaml
app:
  title: Backstage DevOps - British Airways Training
  baseUrl: http://backstage.kind.local

backend:
  baseUrl: http://backstage.kind.local
  listen:
    port: 7007
    host: 0.0.0.0
  cors:
    origin: http://backstage.kind.local
  database:
    client: pg
    connection:
      host: ${POSTGRES_HOST}
      port: ${POSTGRES_PORT}
      user: ${POSTGRES_USER}
      password: ${POSTGRES_PASSWORD}
      database: ${POSTGRES_DB}
```

#### 4.2 Crear Manifiestos de Kubernetes

Ver carpeta `kubernetes/` para todos los manifiestos:
- `namespace.yaml` - Namespace backstage
- `configmap.yaml` - ConfigMap con app-config.kubernetes.yaml
- `secrets.yaml` - Secrets (PostgreSQL, GitHub, ArgoCD)
- `rbac.yaml` - ServiceAccount, Role, RoleBinding
- `deployment.yaml` - Deployment con 3 réplicas
- `service.yaml` - ClusterIP service
- `ingress.yaml` - Ingress para backstage.kind.local

---

### FASE 5: Construir Imagen Docker (30 min)

#### 5.1 Crear Dockerfile.production
**Archivo**: `backstage/Dockerfile.production`

(Ver contenido completo en sección de scripts)

#### 5.2 Build y Load en Kind
```bash
cd /Users/jaime.henao/arheanja/Backstage-solutions/backstage-kind-migration

# Build
docker build -f backstage/Dockerfile.production -t backstage-kind:latest .

# Load en Kind
kind load docker-image backstage-kind:latest --name kind

# Verificar
docker exec kind-control-plane crictl images | grep backstage
```

---

### FASE 6: Deploy en Kind (30 min)

#### 6.1 Aplicar Manifiestos
```bash
# Namespace
kubectl apply -f kubernetes/namespace.yaml

# RBAC
kubectl apply -f kubernetes/rbac.yaml

# Secrets
kubectl apply -f kubernetes/secrets.yaml

# ConfigMap
kubectl apply -f kubernetes/configmap.yaml

# Service
kubectl apply -f kubernetes/service.yaml

# Deployment
kubectl apply -f kubernetes/deployment.yaml

# Ingress
kubectl apply -f kubernetes/ingress.yaml
```

#### 6.2 Verificar Deployment
```bash
# Pods
kubectl get pods -n backstage

# Logs
kubectl logs -n backstage -l app=backstage --tail=50

# Health check
kubectl exec -n backstage deployment/backstage -- curl -f http://localhost:7007/healthcheck
```

---

### FASE 7: Testing y Validación (1 hora)

#### 7.1 Health Checks
- [ ] Pods en estado Running (3/3)
- [ ] Service endpoints configurados
- [ ] Ingress resuelve a backstage.kind.local
- [ ] Health check endpoint responde 200 OK

#### 7.2 Feature Testing
- [ ] Landing page carga
- [ ] Catalog muestra componentes
- [ ] Kubernetes integration funciona
- [ ] ArgoCD integration funciona
- [ ] Grafana dashboards accesibles
- [ ] Prometheus métricas visibles

#### 7.3 Performance Testing
- [ ] Response time < 2s
- [ ] Memory usage < 1GB por pod
- [ ] CPU usage < 500m por pod
- [ ] Sin memory leaks después de 1 hora

---

## 📊 Timeline Estimado

```
Fase 1: Auditoría                 → 30 min
Fase 2: Setup Nuevo Proyecto      → 1 hora
Fase 3: Migrar Configuraciones    → 1.5 horas
Fase 4: Config Kubernetes         → 1 hora
Fase 5: Build Imagen              → 30 min
Fase 6: Deploy en Kind            → 30 min
Fase 7: Testing                   → 1 hora
─────────────────────────────────────────
TOTAL:                             6 horas
```

**Timeline Optimista**: 4 horas (si todo funciona a la primera)
**Timeline Realista**: 6 horas
**Timeline Conservador**: 8 horas (con troubleshooting)

---

## ✅ Checklist de Éxito

### Pre-Deployment
- [ ] Nuevo proyecto Backstage creado
- [ ] Todos los plugins instalados
- [ ] Configuraciones migradas
- [ ] Imagen Docker construida
- [ ] Imagen cargada en Kind

### Post-Deployment
- [ ] 3 pods Running en namespace backstage
- [ ] Health checks pasan
- [ ] Ingress resuelve correctamente
- [ ] Kubernetes integration funciona
- [ ] ArgoCD integration funciona
- [ ] Observability (Grafana/Prometheus) funciona
- [ ] Catalog carga componentes

### Cleanup
- [ ] Documentación actualizada
- [ ] Scripts funcionando
- [ ] README actualizado con instrucciones

---

## 🔄 Rollback Plan

### Si el nuevo deployment falla:
1. El proyecto anterior en `/backstage-app-devc` sigue intacto
2. El deployment anterior en Kind sigue funcionando (si no se limpió)
3. Simplemente continuar usando el devcontainer hasta resolver issues

### Ventajas de Fresh Start:
- ✅ No se toca el proyecto original
- ✅ Podemos comparar lado a lado
- ✅ Fácil de borrar y empezar de nuevo
- ✅ Sin riesgo de corrupción

---

**Status**: 📋 Documented - Ready to Execute

**Next Action**: Ejecutar Fase 1 - Auditoría
