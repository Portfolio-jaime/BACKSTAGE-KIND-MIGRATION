# Guía Completa de Configuración de Backstage

Esta guía cubre cómo configurar, actualizar, instalar plugins y personalizar tu instancia de Backstage.

## 📋 Tabla de Contenidos

1. [Configuración Básica](#configuración-básica)
2. [Instalación de Plugins](#instalación-de-plugins)
3. [Configuración de Autenticación](#configuración-de-autenticación)
4. [Configuración de Base de Datos](#configuración-de-base-de-datos)
5. [Integración con Kubernetes](#integración-con-kubernetes)
6. [Configuración de Catálogo](#configuración-de-catálogo)
7. [TechDocs](#techdocs)
8. [Personalización de UI](#personalización-de-ui)
9. [Variables de Entorno](#variables-de-entorno)
10. [Actualización de Backstage](#actualización-de-backstage)

---

## 🔧 Configuración Básica

### app-config.yaml

El archivo principal de configuración de Backstage es `app-config.yaml` en la raíz del proyecto.

#### Estructura Básica

```yaml
app:
  title: Platform Engineering Portal
  baseUrl: http://backstage.kind.local

organization:
  name: Your Organization

backend:
  baseUrl: http://backstage.kind.local
  listen:
    port: 7007
    host: 0.0.0.0

  cors:
    origin: http://backstage.kind.local
    methods: [GET, HEAD, PATCH, POST, PUT, DELETE]
    credentials: true

  database:
    client: pg
    connection:
      host: ${POSTGRES_HOST}
      port: ${POSTGRES_PORT}
      user: ${POSTGRES_USER}
      password: ${POSTGRES_PASSWORD}

integrations:
  github:
    - host: github.com
      token: ${GITHUB_TOKEN}

proxy:
  '/prometheus':
    target: 'http://prometheus-prometheus.monitoring.svc.cluster.local:9090'
    changeOrigin: true

  '/grafana':
    target: 'http://grafana.monitoring.svc.cluster.local:3000'
    changeOrigin: true

catalog:
  rules:
    - allow: [Component, System, API, Resource, Location]

  locations:
    # Local catalog
    - type: file
      target: ../../catalog/catalog-info.yaml
      rules:
        - allow: [Component, System, API, Group, User, Resource, Location]

    # Platform services
    - type: file
      target: ../../backstage-catalog/platform-services.yaml
      rules:
        - allow: [Component, System, API, Resource]
```

### app-config.production.yaml

Para producción, crea un archivo separado con configuraciones específicas:

```yaml
app:
  baseUrl: https://backstage.your-domain.com

backend:
  baseUrl: https://backstage.your-domain.com
  database:
    client: pg
    connection:
      host: ${POSTGRES_HOST}
      port: ${POSTGRES_PORT}
      user: ${POSTGRES_USER}
      password: ${POSTGRES_PASSWORD}
      ssl:
        rejectUnauthorized: false

auth:
  providers:
    github:
      production:
        clientId: ${GITHUB_CLIENT_ID}
        clientSecret: ${GITHUB_CLIENT_SECRET}
```

### Uso de Múltiples Archivos de Configuración

```bash
# Desarrollo
yarn start

# Producción
yarn start --config app-config.yaml --config app-config.production.yaml
```

---

## 📦 Instalación de Plugins

### Plugins Oficiales Recomendados

#### 1. Kubernetes Plugin

**Instalación**:

```bash
# Backend
cd packages/backend
yarn add @backstage/plugin-kubernetes-backend

# Frontend
cd ../app
yarn add @backstage/plugin-kubernetes
```

**Configuración Backend** (`packages/backend/src/plugins/kubernetes.ts`):

```typescript
import { KubernetesBuilder } from '@backstage/plugin-kubernetes-backend';
import { Router } from 'express';
import { PluginEnvironment } from '../types';
import { CatalogClient } from '@backstage/catalog-client';

export default async function createPlugin(
  env: PluginEnvironment,
): Promise<Router> {
  const catalogApi = new CatalogClient({ discoveryApi: env.discovery });
  const { router } = await KubernetesBuilder.createBuilder({
    logger: env.logger,
    config: env.config,
    catalogApi,
    permissions: env.permissions,
  }).build();
  return router;
}
```

**Registro en Backend** (`packages/backend/src/index.ts`):

```typescript
import kubernetes from './plugins/kubernetes';

// ...

const kubernetesEnv = useHotMemoize(module, () => createEnv('kubernetes'));

// ...

apiRouter.use('/kubernetes', await kubernetes(kubernetesEnv));
```

**Configuración en app-config.yaml**:

```yaml
kubernetes:
  serviceLocatorMethod:
    type: 'multiTenant'
  clusterLocatorMethods:
    - type: 'config'
      clusters:
        - url: https://kubernetes.default.svc
          name: kind-kind
          authProvider: 'serviceAccount'
          skipTLSVerify: true
          skipMetricsLookup: true
          serviceAccountToken: ${K8S_SA_TOKEN}
```

**Uso en Frontend** (`packages/app/src/components/catalog/EntityPage.tsx`):

```typescript
import { EntityKubernetesContent } from '@backstage/plugin-kubernetes';

// En la página de entidad
const serviceEntityPage = (
  <EntityLayout>
    <EntityLayout.Route path="/kubernetes" title="Kubernetes">
      <EntityKubernetesContent refreshIntervalMs={30000} />
    </EntityLayout.Route>
  </EntityLayout>
);
```

#### 2. GitHub Actions Plugin

**Instalación**:

```bash
cd packages/app
yarn add @backstage/plugin-github-actions
```

**Uso**:

```typescript
import { EntityGithubActionsContent } from '@backstage/plugin-github-actions';

// En EntityPage.tsx
<EntityLayout.Route path="/github-actions" title="GitHub Actions">
  <EntityGithubActionsContent />
</EntityLayout.Route>
```

**Configuración**:

```yaml
# app-config.yaml
integrations:
  github:
    - host: github.com
      token: ${GITHUB_TOKEN}
```

#### 3. ArgoCD Plugin

**Instalación**:

```bash
# Backend
cd packages/backend
yarn add @roadiehq/backstage-plugin-argo-cd-backend

# Frontend
cd ../app
yarn add @roadiehq/backstage-plugin-argo-cd
```

**Configuración**:

```yaml
# app-config.yaml
argocd:
  appLocatorMethods:
    - type: 'config'
      instances:
        - name: argocd
          url: http://argocd.kind.local
          token: ${ARGOCD_AUTH_TOKEN}
```

**Uso**:

```typescript
import { EntityArgoCDContent } from '@roadiehq/backstage-plugin-argo-cd';

<EntityLayout.Route path="/argocd" title="ArgoCD">
  <EntityArgoCDContent />
</EntityLayout.Route>
```

#### 4. Prometheus Plugin

**Instalación**:

```bash
cd packages/app
yarn add @roadiehq/backstage-plugin-prometheus
```

**Configuración**:

```yaml
# app-config.yaml
proxy:
  '/prometheus/api':
    target: 'http://prometheus-prometheus.monitoring.svc.cluster.local:9090/api/v1/'
    changeOrigin: true
    secure: false
```

#### 5. Grafana Plugin

**Instalación**:

```bash
cd packages/app
yarn add @k-phoen/backstage-plugin-grafana
```

**Configuración**:

```yaml
# app-config.yaml
grafana:
  domain: http://grafana.kind.local
  unifiedAlerting: false
```

### Plugins de Comunidad

#### Tech Radar

**Instalación**:

```bash
cd packages/app
yarn add @backstage/plugin-tech-radar
```

**Configuración** (`packages/app/src/components/techRadar/TechRadarPage.tsx`):

```typescript
import React from 'react';
import {
  TechRadarPage,
  TechRadarApi,
  TechRadarLoaderResponse,
} from '@backstage/plugin-tech-radar';

const getSampleData = (): Promise<TechRadarLoaderResponse> => {
  return Promise.resolve({
    entries: [
      {
        timeline: [
          {
            moved: 0,
            ringId: 'use',
            date: new Date('2024-01-01'),
          },
        ],
        url: '#',
        key: 'react',
        id: 'react',
        title: 'React',
        quadrant: 'languages-and-frameworks',
      },
      // ... más tecnologías
    ],
    quadrants: [
      { id: 'languages-and-frameworks', name: 'Languages & Frameworks' },
      { id: 'tools', name: 'Tools' },
      { id: 'techniques', name: 'Techniques' },
      { id: 'platforms', name: 'Platforms' },
    ],
    rings: [
      { id: 'use', name: 'USE', color: '#93c47d' },
      { id: 'trial', name: 'TRIAL', color: '#93d2c2' },
      { id: 'assess', name: 'ASSESS', color: '#fbdb84' },
      { id: 'hold', name: 'HOLD', color: '#efafa9' },
    ],
  });
};

export const TechRadarComponent = () => (
  <TechRadarPage width={1500} height={800} getData={getSampleData} />
);
```

---

## 🔐 Configuración de Autenticación

### GitHub OAuth

#### Paso 1: Crear OAuth App en GitHub

1. Ve a GitHub Settings → Developer settings → OAuth Apps → New OAuth App
2. Configura:
   - **Application name**: Backstage
   - **Homepage URL**: `http://backstage.kind.local`
   - **Authorization callback URL**: `http://backstage.kind.local/api/auth/github/handler/frame`
3. Guarda el Client ID y Client Secret

#### Paso 2: Configurar en Backstage

```yaml
# app-config.yaml
auth:
  environment: development
  providers:
    github:
      development:
        clientId: ${GITHUB_CLIENT_ID}
        clientSecret: ${GITHUB_CLIENT_SECRET}
```

#### Paso 3: Configurar Sign-In Resolver

```typescript
// packages/backend/src/plugins/auth.ts
import { createRouter } from '@backstage/plugin-auth-backend';
import {
  DEFAULT_NAMESPACE,
  stringifyEntityRef,
} from '@backstage/catalog-model';

export default async function createPlugin(
  env: PluginEnvironment,
): Promise<Router> {
  return await createRouter({
    logger: env.logger,
    config: env.config,
    database: env.database,
    discovery: env.discovery,
    tokenManager: env.tokenManager,
    providerFactories: {
      github: providers.github.create({
        signIn: {
          resolver: async ({ profile }, ctx) => {
            if (!profile.email) {
              throw new Error('GitHub profile must contain an email');
            }

            const [localPart] = profile.email.split('@');

            const userEntityRef = stringifyEntityRef({
              kind: 'User',
              name: localPart,
              namespace: DEFAULT_NAMESPACE,
            });

            return ctx.issueToken({
              claims: {
                sub: userEntityRef,
                ent: [userEntityRef],
              },
            });
          },
        },
      }),
    },
  });
}
```

### Microsoft/Azure AD

```yaml
auth:
  providers:
    microsoft:
      development:
        clientId: ${AZURE_CLIENT_ID}
        clientSecret: ${AZURE_CLIENT_SECRET}
        tenantId: ${AZURE_TENANT_ID}
```

### Google OAuth

```yaml
auth:
  providers:
    google:
      development:
        clientId: ${GOOGLE_CLIENT_ID}
        clientSecret: ${GOOGLE_CLIENT_SECRET}
```

---

## 💾 Configuración de Base de Datos

### PostgreSQL (Recomendado para Producción)

#### Configuración

```yaml
# app-config.yaml
backend:
  database:
    client: pg
    connection:
      host: ${POSTGRES_HOST}
      port: ${POSTGRES_PORT}
      user: ${POSTGRES_USER}
      password: ${POSTGRES_PASSWORD}
      database: backstage
```

#### Variables de Entorno

```bash
# .env
POSTGRES_HOST=psql-postgresql.backstage.svc.cluster.local
POSTGRES_PORT=5432
# POSTGRES_USER y POSTGRES_PASSWORD se obtienen del secret 'backstage-secrets'
# POSTGRES_USER=backstage
# POSTGRES_PASSWORD=your-secure-password
```

#### Desplegar PostgreSQL en Kubernetes

```bash
# PostgreSQL ahora se despliega a través de ArgoCD usando el chart de Helm local
# en helm-charts/postgresql. Las credenciales se gestionan a través del secret 'backstage-secrets'.
# No es necesario ejecutar 'helm install' directamente.
```

### SQLite (Solo para Desarrollo)

```yaml
backend:
  database:
    client: better-sqlite3
    connection: ':memory:'
```

---

## ☸️ Integración con Kubernetes

### ServiceAccount y RBAC

```yaml
# kubernetes/backstage-rbac.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backstage
  namespace: backstage
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: backstage-read
rules:
  - apiGroups:
      - '*'
    resources:
      - pods
      - configmaps
      - services
      - deployments
      - replicasets
      - horizontalpodautoscalers
      - ingresses
      - statefulsets
      - limitranges
      - resourcequotas
      - daemonsets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - batch
    resources:
      - jobs
      - cronjobs
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - metrics.k8s.io
    resources:
      - pods
    verbs:
      - get
      - list
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: backstage-read-binding
subjects:
  - kind: ServiceAccount
    name: backstage
    namespace: backstage
roleRef:
  kind: ClusterRole
  name: backstage-read
  apiGroup: rbac.authorization.k8s.io
```

### Obtener Token del ServiceAccount

```bash
# Obtener el secreto
kubectl get secrets -n backstage | grep backstage-token

# Obtener el token
kubectl get secret <secret-name> -n backstage -o jsonpath='{.data.token}' | base64 -d

# O usar este comando directo
kubectl create token backstage -n backstage --duration=87600h
```

### Configurar Token

```yaml
# app-config.yaml
kubernetes:
  serviceLocatorMethod:
    type: 'multiTenant'
  clusterLocatorMethods:
    - type: 'config'
      clusters:
        - url: https://kubernetes.default.svc
          name: kind-kind
          authProvider: 'serviceAccount'
          skipTLSVerify: true
          skipMetricsLookup: false
          serviceAccountToken: ${K8S_SA_TOKEN}
```

---

## 📚 Configuración de Catálogo

### Estructura del Catálogo

#### Component

```yaml
# catalog/components/my-service.yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: my-service
  title: My Microservice
  description: A microservice that does something
  annotations:
    github.com/project-slug: myorg/my-service
    backstage.io/kubernetes-id: my-service
    backstage.io/kubernetes-namespace: production
    prometheus.io/rule: 'sum(rate(http_requests_total{job="my-service"}[5m]))'
  tags:
    - nodejs
    - typescript
    - api
  links:
    - url: https://my-service.com
      title: Service URL
      icon: web
    - url: https://my-service.com/swagger
      title: API Docs
      icon: docs
spec:
  type: service
  lifecycle: production
  owner: team-backend
  system: platform
  providesApis:
    - my-api
  consumesApis:
    - auth-api
```

#### System

```yaml
# catalog/systems/platform.yaml
apiVersion: backstage.io/v1alpha1
kind: System
metadata:
  name: platform
  title: Platform System
  description: Core platform services
spec:
  owner: platform-engineering
  domain: infrastructure
```

#### API

```yaml
# catalog/apis/my-api.yaml
apiVersion: backstage.io/v1alpha1
kind: API
metadata:
  name: my-api
  title: My Service API
  description: RESTful API for My Service
spec:
  type: openapi
  lifecycle: production
  owner: team-backend
  system: platform
  definition: |
    openapi: 3.0.0
    info:
      title: My API
      version: 1.0.0
    paths:
      /health:
        get:
          summary: Health check
          responses:
            '200':
              description: OK
```

#### Group/Team

```yaml
# catalog/org/teams.yaml
apiVersion: backstage.io/v1alpha1
kind: Group
metadata:
  name: platform-engineering
  title: Platform Engineering Team
  description: Team responsible for platform infrastructure
spec:
  type: team
  profile:
    displayName: Platform Engineering
    email: platform@yourorg.com
  parent: engineering
  children: []
  members:
    - user:john.doe
    - user:jane.smith
```

#### User

```yaml
# catalog/org/users.yaml
apiVersion: backstage.io/v1alpha1
kind: User
metadata:
  name: john.doe
spec:
  profile:
    displayName: John Doe
    email: john.doe@yourorg.com
    picture: https://avatars.githubusercontent.com/u/12345
  memberOf:
    - platform-engineering
```

### Importar desde GitHub

```yaml
# app-config.yaml
catalog:
  locations:
    - type: url
      target: https://github.com/myorg/myrepo/blob/main/catalog-info.yaml
      rules:
        - allow: [Component, System, API]

    # Autodiscovery
    - type: github-discovery
      target: https://github.com/myorg/*/blob/main/catalog-info.yaml
```

---

## 📖 TechDocs

### Configuración

```yaml
# app-config.yaml
techdocs:
  builder: 'local'
  generator:
    runIn: 'local'
  publisher:
    type: 'local'
```

### Estructura de Documentación

```
my-service/
├── catalog-info.yaml
├── docs/
│   ├── index.md
│   ├── architecture.md
│   └── api.md
└── mkdocs.yml
```

### mkdocs.yml

```yaml
site_name: 'My Service Documentation'
site_description: 'Documentation for My Service'

nav:
  - Home: index.md
  - Architecture: architecture.md
  - API: api.md

plugins:
  - techdocs-core
```

### Anotar Component

```yaml
metadata:
  annotations:
    backstage.io/techdocs-ref: dir:.
```

---

## 🎨 Personalización de UI

### Logo Personalizado

Reemplaza los logos en:
- `packages/app/src/components/Root/LogoFull.tsx`
- `packages/app/src/components/Root/LogoIcon.tsx`

```typescript
// LogoFull.tsx
import React from 'react';

const LogoFull = () => {
  return <img src="/path/to/your/logo.png" alt="Company Logo" />;
};

export default LogoFull;
```

### Tema Personalizado

```typescript
// packages/app/src/theme.ts
import { createTheme, lightTheme } from '@backstage/theme';

export const customTheme = createTheme({
  palette: {
    ...lightTheme.palette,
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#ff9800',
    },
  },
  fontFamily: 'Arial, sans-serif',
});
```

Aplica el tema en `App.tsx`:

```typescript
import { customTheme } from './theme';

const app = createApp({
  themes: [{
    id: 'custom-theme',
    title: 'Custom Theme',
    variant: 'light',
    Provider: ({ children }) => (
      <UnifiedThemeProvider theme={customTheme}>
        {children}
      </UnifiedThemeProvider>
    ),
  }],
});
```

### Homepage Personalizada

```typescript
// packages/app/src/components/home/HomePage.tsx
import React from 'react';
import { Grid, Card, CardContent, Typography } from '@material-ui/core';
import { Content, Page, Header } from '@backstage/core-components';

export const HomePage = () => (
  <Page themeId="home">
    <Header title="Welcome to Platform Engineering Portal" />
    <Content>
      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h5">Quick Links</Typography>
              {/* Add your quick links */}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Content>
  </Page>
);
```

---

## 🔐 Variables de Entorno

### Archivo .env

```bash
# GitHub Integration
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
GITHUB_CLIENT_ID=xxxxxxxxxxxxxxxxxxxx
GITHUB_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxx

# PostgreSQL
POSTGRES_HOST=psql-postgresql.backstage.svc.cluster.local
POSTGRES_PORT=5432
POSTGRES_USER=backstage
POSTGRES_PASSWORD=your-secure-password

# Kubernetes
K8S_SA_TOKEN=eyJhbGciOiJSUzI1NiIsImtpZCI6Ii...

# ArgoCD
ARGOCD_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxx

# Auth
AUTH_GITHUB_CLIENT_ID=xxxxxxxxxxxxxxxxxxxx
AUTH_GITHUB_CLIENT_SECRET=xxxxxxxxxxxxxxxxxxxx

# Backstage Backend Secret (for authentication token signing)
BACKEND_SECRET=your-random-backend-secret
```

### ConfigMap en Kubernetes

```yaml
# kubernetes/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backstage-env-config
  namespace: backstage
data:
  POSTGRES_HOST: "psql-postgresql.backstage.svc.cluster.local"
  POSTGRES_PORT: "5432"
  POSTGRES_USER: "backstage"
```

### Secret en Kubernetes

```yaml
# kubernetes/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: backstage-secrets
  namespace: backstage
type: Opaque
stringData:
  POSTGRES_PASSWORD: "your-secure-password"
  GITHUB_TOKEN: "ghp_xxxxxxxxxxxxxxxxxxxx"
  K8S_SA_TOKEN: "eyJhbGciOiJSUzI1NiIsImtpZCI6Ii..."
```

### Secret para Backend de Backstage

```yaml
# kubernetes/backstage-backend-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: backstage-backend-secret
  namespace: backstage
type: Opaque
stringData:
  BACKEND_SECRET: "your-random-backend-secret"
```

---

## 🔄 Actualización de Backstage

### Actualizar a Nueva Versión

#### Paso 1: Verificar Versión Actual

```bash
yarn backstage-cli --version
```

#### Paso 2: Actualizar Backstage CLI

```bash
yarn add --dev @backstage/cli@latest
```

#### Paso 3: Ejecutar Upgrade Helper

```bash
yarn backstage-cli versions:bump
```

#### Paso 4: Actualizar Dependencias

```bash
yarn install
```

#### Paso 5: Ejecutar Migraciones

```bash
yarn backstage-cli migrate
```

#### Paso 6: Verificar Cambios

```bash
git diff package.json
```

#### Paso 7: Test y Build

```bash
# Test local
yarn start

# Build
yarn build:backend
```

### Actualizar Plugins

```bash
# Ver versiones disponibles
yarn outdated

# Actualizar plugin específico
yarn upgrade @backstage/plugin-kubernetes

# Actualizar todos los plugins de Backstage
yarn upgrade-interactive --pattern @backstage
```

### Changelog y Breaking Changes

Siempre revisa:
- [Backstage Releases](https://github.com/backstage/backstage/releases)
- [Upgrade Helper](https://backstage.github.io/upgrade-helper/)

---

## 🔧 Debugging y Logs

### Habilitar Debug Logs

```yaml
# app-config.yaml
backend:
  logger:
    level: debug
```

### Ver Logs en Kubernetes

```bash
# Logs de Backstage
kubectl logs -f deployment/backstage -n backstage

# Logs con filtro
kubectl logs -f deployment/backstage -n backstage | grep ERROR

# Logs de múltiples pods
kubectl logs -l app=backstage -n backstage --all-containers
```

---

## ✅ Checklist de Configuración

- [ ] app-config.yaml configurado
- [ ] Base de datos PostgreSQL funcionando
- [ ] Autenticación configurada (GitHub/Azure/Google)
- [ ] Integración con GitHub configurada
- [ ] Kubernetes plugin instalado y configurado
- [ ] Catálogo importado
- [ ] TechDocs configurado
- [ ] Logo y tema personalizados
- [ ] Variables de entorno en Kubernetes
- [ ] Páginas personalizadas agregadas
- [ ] Build y deployment exitoso

---

**Documentación creada**: Enero 2025
**Versión de Backstage**: Compatible con v1.x
**Autor**: Jaime Henao
