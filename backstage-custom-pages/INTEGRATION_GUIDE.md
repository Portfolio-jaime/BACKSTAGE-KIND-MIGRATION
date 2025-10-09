# Guía de Integración de Páginas Personalizadas en Backstage

Esta guía te muestra cómo integrar las páginas personalizadas (Monitoring, GitOps, Kubernetes, GitHub) en tu instalación de Backstage.

## 📋 Tabla de Contenidos

1. [Requisitos Previos](#requisitos-previos)
2. [Estructura de Archivos](#estructura-de-archivos)
3. [Instalación de Dependencias](#instalación-de-dependencias)
4. [Copiar Componentes](#copiar-componentes)
5. [Modificar App.tsx (Rutas)](#modificar-apptsx-rutas)
6. [Modificar Root.tsx (Sidebar)](#modificar-roottsx-sidebar)
7. [Build y Deployment](#build-y-deployment)
8. [Troubleshooting](#troubleshooting)

---

## 📦 Requisitos Previos

- Backstage instalado y funcionando
- Node.js 18+ y Yarn instalados
- Acceso al código fuente de Backstage
- Permisos para modificar archivos de configuración

## 📁 Estructura de Archivos

Las páginas personalizadas están organizadas así:

```
backstage-custom-pages/
├── components/
│   ├── monitoring/
│   │   ├── MonitoringPage.tsx
│   │   └── index.ts
│   ├── gitops/
│   │   ├── GitOpsPage.tsx
│   │   └── index.ts
│   ├── kubernetes/
│   │   ├── KubernetesPage.tsx
│   │   └── index.ts
│   └── github/
│       ├── GitHubPage.tsx
│       └── index.ts
├── INTEGRATION_GUIDE.md (este archivo)
└── README.md
```

## 📦 Instalación de Dependencias

Estas páginas utilizan Material-UI que ya viene con Backstage. No necesitas instalar dependencias adicionales para los componentes básicos.

Sin embargo, asegúrate de tener las dependencias de Backstage instaladas:

```bash
cd packages/app
yarn install
```

## 📋 Copiar Componentes

### Paso 1: Crear directorio para páginas personalizadas

En el directorio raíz de tu proyecto Backstage:

```bash
# Navega al directorio de tu app
cd packages/app/src

# Crea directorio para componentes personalizados
mkdir -p components/custom-pages
```

### Paso 2: Copiar archivos de componentes

Copia cada carpeta de componentes a la ubicación de Backstage:

```bash
# Desde el directorio backstage-custom-pages/components/
cp -r monitoring/ <ruta-a-backstage>/packages/app/src/components/custom-pages/
cp -r gitops/ <ruta-a-backstage>/packages/app/src/components/custom-pages/
cp -r kubernetes/ <ruta-a-backstage>/packages/app/src/components/custom-pages/
cp -r github/ <ruta-a-backstage>/packages/app/src/components/custom-pages/
```

Tu estructura debería verse así:

```
packages/app/src/components/
├── custom-pages/
│   ├── monitoring/
│   │   ├── MonitoringPage.tsx
│   │   └── index.ts
│   ├── gitops/
│   │   ├── GitOpsPage.tsx
│   │   └── index.ts
│   ├── kubernetes/
│   │   ├── KubernetesPage.tsx
│   │   └── index.ts
│   └── github/
│       ├── GitHubPage.tsx
│       └── index.ts
└── ... (otros componentes existentes)
```

## 🛣️ Modificar App.tsx (Rutas)

El archivo `App.tsx` define las rutas de la aplicación.

**Ubicación**: `packages/app/src/App.tsx`

### Paso 1: Importar las páginas personalizadas

Agrega estos imports al inicio del archivo, después de los imports existentes:

```typescript
// Custom Pages
import { MonitoringPage } from './components/custom-pages/monitoring';
import { GitOpsPage } from './components/custom-pages/gitops';
import { KubernetesPage } from './components/custom-pages/kubernetes';
import { GitHubPage } from './components/custom-pages/github';
```

### Paso 2: Agregar rutas

Dentro del componente `<FlatRoutes>`, agrega las nuevas rutas:

```typescript
const routes = (
  <FlatRoutes>
    {/* ... rutas existentes ... */}

    {/* Custom Platform Pages */}
    <Route path="/monitoring" element={<MonitoringPage />} />
    <Route path="/gitops" element={<GitOpsPage />} />
    <Route path="/kubernetes" element={<KubernetesPage />} />
    <Route path="/github" element={<GitHubPage />} />

    {/* ... más rutas existentes ... */}
  </FlatRoutes>
);
```

### Ejemplo completo de sección relevante en App.tsx:

```typescript
import React from 'react';
import { Navigate, Route } from 'react-router-dom';
import { apiDocsPlugin, ApiExplorerPage } from '@backstage/plugin-api-docs';
import {
  CatalogEntityPage,
  CatalogIndexPage,
  catalogPlugin,
} from '@backstage/plugin-catalog';
import {
  CatalogImportPage,
  catalogImportPlugin,
} from '@backstage/plugin-catalog-import';
import { ScaffolderPage, scaffolderPlugin } from '@backstage/plugin-scaffolder';
import { orgPlugin } from '@backstage/plugin-org';
import { SearchPage } from '@backstage/plugin-search';
import { TechRadarPage } from '@backstage/plugin-tech-radar';
import {
  TechDocsIndexPage,
  techdocsPlugin,
  TechDocsReaderPage,
} from '@backstage/plugin-techdocs';
import { TechDocsAddons } from '@backstage/plugin-techdocs-react';
import { ReportIssue } from '@backstage/plugin-techdocs-module-addons-contrib';
import { UserSettingsPage } from '@backstage/plugin-user-settings';
import { apis } from './apis';
import { entityPage } from './components/catalog/EntityPage';
import { searchPage } from './components/search/SearchPage';
import { Root } from './components/Root';

// Custom Pages
import { MonitoringPage } from './components/custom-pages/monitoring';
import { GitOpsPage } from './components/custom-pages/gitops';
import { KubernetesPage } from './components/custom-pages/kubernetes';
import { GitHubPage } from './components/custom-pages/github';

import { AlertDisplay, OAuthRequestDialog } from '@backstage/core-components';
import { createApp } from '@backstage/app-defaults';
import { AppRouter, FlatRoutes } from '@backstage/core-app-api';
import { CatalogGraphPage } from '@backstage/plugin-catalog-graph';
import { RequirePermission } from '@backstage/plugin-permission-react';
import { catalogEntityCreatePermission } from '@backstage/plugin-catalog-common/alpha';

const app = createApp({
  apis,
  bindRoutes({ bind }) {
    bind(catalogPlugin.externalRoutes, {
      createComponent: scaffolderPlugin.routes.root,
      viewTechDoc: techdocsPlugin.routes.docRoot,
    });
    bind(apiDocsPlugin.externalRoutes, {
      registerApi: catalogImportPlugin.routes.importPage,
    });
    bind(scaffolderPlugin.externalRoutes, {
      registerComponent: catalogImportPlugin.routes.importPage,
    });
    bind(orgPlugin.externalRoutes, {
      catalogIndex: catalogPlugin.routes.catalogIndex,
    });
  },
});

const routes = (
  <FlatRoutes>
    <Route path="/" element={<Navigate to="catalog" />} />
    <Route path="/catalog" element={<CatalogIndexPage />} />
    <Route
      path="/catalog/:namespace/:kind/:name"
      element={<CatalogEntityPage />}
    >
      {entityPage}
    </Route>
    <Route path="/docs" element={<TechDocsIndexPage />} />
    <Route
      path="/docs/:namespace/:kind/:name/*"
      element={<TechDocsReaderPage />}
    >
      <TechDocsAddons>
        <ReportIssue />
      </TechDocsAddons>
    </Route>
    <Route path="/create" element={<ScaffolderPage />} />
    <Route path="/api-docs" element={<ApiExplorerPage />} />
    <Route
      path="/tech-radar"
      element={<TechRadarPage width={1500} height={800} />}
    />
    <Route
      path="/catalog-import"
      element={
        <RequirePermission permission={catalogEntityCreatePermission}>
          <CatalogImportPage />
        </RequirePermission>
      }
    />
    <Route path="/search" element={<SearchPage />}>
      {searchPage}
    </Route>
    <Route path="/settings" element={<UserSettingsPage />} />
    <Route path="/catalog-graph" element={<CatalogGraphPage />} />

    {/* Custom Platform Pages */}
    <Route path="/monitoring" element={<MonitoringPage />} />
    <Route path="/gitops" element={<GitOpsPage />} />
    <Route path="/kubernetes" element={<KubernetesPage />} />
    <Route path="/github" element={<GitHubPage />} />
  </FlatRoutes>
);

export default app.createRoot(
  <>
    <AlertDisplay />
    <OAuthRequestDialog />
    <AppRouter>
      <Root>{routes}</Root>
    </AppRouter>
  </>,
);
```

## 🎨 Modificar Root.tsx (Sidebar)

El archivo `Root.tsx` define el sidebar (menú lateral izquierdo).

**Ubicación**: `packages/app/src/components/Root/Root.tsx`

### Paso 1: Importar iconos necesarios

Si no están ya importados, agrega estos imports:

```typescript
import ShowChartIcon from '@material-ui/icons/ShowChart';
import CloudSyncIcon from '@material-ui/icons/CloudSync';
import CloudIcon from '@material-ui/icons/Cloud';
import GitHubIcon from '@material-ui/icons/GitHub';
```

### Paso 2: Agregar elementos al sidebar

Encuentra la sección `<SidebarScrollWrapper>` y agrega los nuevos items:

```typescript
<SidebarScrollWrapper>
  <SidebarItem icon={HomeIcon} to="catalog" text="Home" />
  <Menu />
  <SidebarDivider />

  {/* Platform Section */}
  <SidebarItem icon={CloudIcon} to="kubernetes" text="Kubernetes" />
  <SidebarItem icon={ShowChartIcon} to="monitoring" text="Monitoring" />
  <SidebarItem icon={CloudSyncIcon} to="gitops" text="GitOps" />
  <SidebarItem icon={GitHubIcon} to="github" text="GitHub" />

  <SidebarDivider />
  <SidebarItem icon={ExtensionIcon} to="api-docs" text="APIs" />
  <SidebarItem icon={LibraryBooks} to="docs" text="Docs" />
  <SidebarItem icon={CreateComponentIcon} to="create" text="Create..." />
  {/* ... resto de items existentes ... */}
</SidebarScrollWrapper>
```

### Ejemplo completo de Root.tsx:

```typescript
import React, { PropsWithChildren } from 'react';
import { makeStyles } from '@material-ui/core';
import HomeIcon from '@material-ui/icons/Home';
import ExtensionIcon from '@material-ui/icons/Extension';
import MapIcon from '@material-ui/icons/MyLocation';
import LibraryBooks from '@material-ui/icons/LibraryBooks';
import CreateComponentIcon from '@material-ui/icons/AddCircleOutline';
import LogoFull from './LogoFull';
import LogoIcon from './LogoIcon';
import { GraphiQLIcon } from '@backstage/plugin-graphiql';
import {
  Settings as SidebarSettings,
  UserSettingsSignInAvatar,
} from '@backstage/plugin-user-settings';
import { SidebarSearchModal } from '@backstage/plugin-search';
import {
  Sidebar,
  sidebarConfig,
  SidebarDivider,
  SidebarGroup,
  SidebarItem,
  SidebarPage,
  SidebarScrollWrapper,
  SidebarSpace,
  useSidebarOpenState,
  Link,
} from '@backstage/core-components';
import MenuIcon from '@material-ui/icons/Menu';
import SearchIcon from '@material-ui/icons/Search';

// Platform icons
import ShowChartIcon from '@material-ui/icons/ShowChart';
import CloudSyncIcon from '@material-ui/icons/CloudSync';
import CloudIcon from '@material-ui/icons/Cloud';
import GitHubIcon from '@material-ui/icons/GitHub';

const useSidebarLogoStyles = makeStyles({
  root: {
    width: sidebarConfig.drawerWidthClosed,
    height: 3 * sidebarConfig.logoHeight,
    display: 'flex',
    flexFlow: 'row nowrap',
    alignItems: 'center',
    marginBottom: -14,
  },
  link: {
    width: sidebarConfig.drawerWidthClosed,
    marginLeft: 24,
  },
});

const SidebarLogo = () => {
  const classes = useSidebarLogoStyles();
  const { isOpen } = useSidebarOpenState();

  return (
    <div className={classes.root}>
      <Link to="/" underline="none" className={classes.link} aria-label="Home">
        {isOpen ? <LogoFull /> : <LogoIcon />}
      </Link>
    </div>
  );
};

export const Root = ({ children }: PropsWithChildren<{}>) => (
  <SidebarPage>
    <Sidebar>
      <SidebarLogo />
      <SidebarGroup label="Search" icon={<SearchIcon />} to="/search">
        <SidebarSearchModal />
      </SidebarGroup>
      <SidebarDivider />
      <SidebarGroup label="Menu" icon={<MenuIcon />}>
        <SidebarScrollWrapper>
          <SidebarItem icon={HomeIcon} to="catalog" text="Home" />

          <SidebarDivider />

          {/* Platform Section */}
          <SidebarItem icon={CloudIcon} to="kubernetes" text="Kubernetes" />
          <SidebarItem icon={ShowChartIcon} to="monitoring" text="Monitoring" />
          <SidebarItem icon={CloudSyncIcon} to="gitops" text="GitOps" />
          <SidebarItem icon={GitHubIcon} to="github" text="GitHub" />

          <SidebarDivider />

          {/* Backstage Features */}
          <SidebarItem icon={ExtensionIcon} to="api-docs" text="APIs" />
          <SidebarItem icon={LibraryBooks} to="docs" text="Docs" />
          <SidebarItem icon={CreateComponentIcon} to="create" text="Create..." />
          <SidebarDivider />
          <SidebarScrollWrapper>
            <SidebarItem icon={MapIcon} to="tech-radar" text="Tech Radar" />
          </SidebarScrollWrapper>
        </SidebarScrollWrapper>
      </SidebarGroup>
      <SidebarSpace />
      <SidebarDivider />
      <SidebarGroup
        label="Settings"
        icon={<UserSettingsSignInAvatar />}
        to="/settings"
      >
        <SidebarSettings />
      </SidebarGroup>
    </Sidebar>
    {children}
  </SidebarPage>
);
```

## 🔧 Personalización de URLs

Las páginas utilizan URLs embebidas en iframes. Actualiza las URLs según tu configuración:

### MonitoringPage.tsx
```typescript
// Líneas 166, 180
<iframe src="http://prometheus.kind.local" ... />
<iframe src="http://grafana.kind.local" ... />
```

### GitOpsPage.tsx
```typescript
// Líneas 180, 194
<iframe src="http://argocd.kind.local/applications" ... />
<iframe src="http://argocd.kind.local" ... />
```

Cambia `kind.local` por tu dominio si es diferente.

## 🏗️ Build y Deployment

### Desarrollo Local

Para probar los cambios localmente:

```bash
# Desde el directorio raíz de Backstage
cd packages/app
yarn start
```

Backstage estará disponible en `http://localhost:3000`

### Build para Producción

#### Paso 1: Build del backend

```bash
# Desde el directorio raíz
yarn build:backend
```

#### Paso 2: Crear imagen Docker

Asegúrate de tener un `Dockerfile` en la raíz de tu proyecto:

```dockerfile
FROM node:18-bullseye-slim

# Install sqlite3 dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends libsqlite3-dev python3 build-essential && \
    rm -rf /var/lib/apt/lists/* && \
    yarn config set python /usr/bin/python3

# Set working directory
WORKDIR /app

# Copy repo skeleton first, to avoid unnecessary docker cache invalidation.
# The skeleton contains the package.json of each package in the monorepo,
# and along with yarn.lock and the root package.json, that's enough to run yarn install
COPY yarn.lock package.json packages/backend/dist/skeleton.tar.gz ./
RUN tar xzf skeleton.tar.gz && rm skeleton.tar.gz

RUN yarn install --frozen-lockfile --production --network-timeout 300000 && rm -rf "$(yarn cache dir)"

# Copy the built packages from the build stage
COPY packages/backend/dist/bundle.tar.gz app-config*.yaml ./
RUN tar xzf bundle.tar.gz && rm bundle.tar.gz

CMD ["node", "packages/backend", "--config", "app-config.yaml"]
```

#### Paso 3: Build de la imagen

```bash
# Build de la imagen
docker build -t backstage:latest .

# Tag con tu registry
docker tag backstage:latest your-registry/backstage:latest

# Push al registry
docker push your-registry/backstage:latest
```

#### Paso 4: Deploy en Kubernetes

Actualiza tu deployment de Kubernetes:

```bash
# Aplicar cambios
kubectl set image deployment/backstage backstage=your-registry/backstage:latest -n backstage

# Verificar rollout
kubectl rollout status deployment/backstage -n backstage

# Ver logs
kubectl logs -f deployment/backstage -n backstage
```

### Script de Deploy Automatizado

Crea un script `deploy.sh`:

```bash
#!/bin/bash
set -e

echo "🔨 Building Backstage backend..."
yarn build:backend

echo "🐳 Building Docker image..."
docker build -t backstage:latest .
docker tag backstage:latest jaimehenao8126/backstage-production:latest

echo "📤 Pushing to registry..."
docker push jaimehenao8126/backstage-production:latest

echo "🚀 Deploying to Kubernetes..."
kubectl set image deployment/backstage backstage=jaimehenao8126/backstage-production:latest -n backstage

echo "⏳ Waiting for rollout..."
kubectl rollout status deployment/backstage -n backstage

echo "✅ Deployment complete!"
kubectl get pods -n backstage
```

Haz el script ejecutable:

```bash
chmod +x deploy.sh
./deploy.sh
```

## 🐛 Troubleshooting

### Problema: Las páginas no aparecen en el sidebar

**Solución**: Verifica que:
1. Los imports en `Root.tsx` son correctos
2. Las rutas en `App.tsx` coinciden con los paths en `Root.tsx`
3. Hiciste rebuild de la aplicación

### Problema: Error "Module not found"

**Solución**:
```bash
# Limpia cache de Yarn
yarn cache clean

# Reinstala dependencias
rm -rf node_modules
yarn install

# Rebuild
yarn build:backend
```

### Problema: Los iframes no cargan

**Solución**:
1. Verifica que los servicios estén corriendo:
   ```bash
   kubectl get pods -n monitoring
   kubectl get pods -n argocd
   ```

2. Verifica los ingresses:
   ```bash
   kubectl get ingress -n monitoring
   kubectl get ingress -n argocd
   ```

3. Verifica /etc/hosts:
   ```bash
   cat /etc/hosts | grep kind.local
   ```

   Debe contener:
   ```
   127.0.0.1 backstage.kind.local
   127.0.0.1 prometheus.kind.local
   127.0.0.1 grafana.kind.local
   127.0.0.1 argocd.kind.local
   127.0.0.1 alertmanager.kind.local
   ```

### Problema: Errores de TypeScript

**Solución**:
```bash
# Verifica tipos
yarn tsc

# Si hay errores, instala tipos faltantes
yarn add --dev @types/react @types/node
```

### Problema: La página se ve mal o sin estilos

**Solución**: Material-UI ya está incluido en Backstage, pero verifica la versión:
```bash
yarn list @material-ui/core
```

Debe ser versión 4.x compatible con Backstage.

### Problema: El build falla

**Solución**: Revisa los logs detallados:
```bash
yarn build:backend --verbose
```

Problemas comunes:
- Falta memoria: Aumenta límite de Node: `NODE_OPTIONS=--max-old-space-size=4096`
- Dependencias desactualizadas: `yarn upgrade`

## 📚 Recursos Adicionales

### Documentación Oficial de Backstage
- [Backstage Getting Started](https://backstage.io/docs/getting-started/)
- [Backstage Architecture](https://backstage.io/docs/overview/architecture-overview)
- [Creating Plugins](https://backstage.io/docs/plugins/create-a-plugin)

### Material-UI (v4)
- [Material-UI v4 Documentation](https://v4.mui.com/)
- [Material-UI Icons](https://v4.mui.com/components/material-icons/)

### Kubernetes & Deployment
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

## ✅ Checklist de Integración

- [ ] Copié los componentes a `packages/app/src/components/custom-pages/`
- [ ] Actualicé `App.tsx` con los imports y rutas
- [ ] Actualicé `Root.tsx` con los items del sidebar
- [ ] Actualicé las URLs de los iframes según mi configuración
- [ ] Hice build local y probé: `yarn start`
- [ ] Hice build del backend: `yarn build:backend`
- [ ] Creé la imagen Docker
- [ ] Desplegué en Kubernetes
- [ ] Verifiqué que las páginas aparecen en el sidebar
- [ ] Verifiqué que los iframes cargan correctamente

## 🎯 Próximos Pasos

Una vez integradas las páginas básicas, puedes:

1. **Agregar autenticación** a los iframes usando OAuth proxy
2. **Personalizar estilos** según tu tema de Backstage
3. **Agregar más pestañas** con información adicional
4. **Integrar APIs** para datos dinámicos en lugar de iframes
5. **Crear plugins personalizados** más avanzados

---

**Documentación creada**: Enero 2025
**Versión de Backstage**: Compatible con v1.x
**Autor**: Jaime Henao
