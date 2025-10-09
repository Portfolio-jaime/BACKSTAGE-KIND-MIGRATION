# 🎨 Custom Pages para Backstage - Sidebar Navigation

Este directorio contiene las páginas custom que aparecerán en el **sidebar izquierdo** de Backstage.

---

## 📋 Páginas Incluidas

1. **Monitoring** (`/monitoring`) - Prometheus + Grafana
2. **GitOps** (`/gitops`) - ArgoCD
3. **Kubernetes** (`/kubernetes`) - Cluster resources
4. **Observability** (`/observability`) - Datadog (cuando se implemente)
5. **GitHub** (`/github`) - Repositories y workflows

---

## 🚀 Cómo Implementar en Backstage

### Prerequisitos

Necesitas acceso al código fuente de Backstage. Si estás usando la imagen `jaimehenao8126/backstage-production:latest`, necesitas:

1. Clonar el repositorio de Backstage
2. Agregar los componentes
3. Rebuild la imagen
4. Actualizar el deployment en Kind

---

## 📁 Estructura de Archivos a Crear

```
backstage-app/
└── packages/
    └── app/
        └── src/
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
            ├── App.tsx (modificar)
            └── components/Root/Root.tsx (modificar)
```

---

## 🔧 Paso a Paso

### Paso 1: Copiar Componentes

Copiar todos los archivos `.tsx` de este directorio a tu proyecto Backstage:

```bash
# Desde este directorio
cd /Users/jaime.henao/arheanja/Backstage-solutions/backstage-kind-migration

# Copiar a tu proyecto Backstage
cp -r backstage-custom-pages/components/* /path/to/backstage-app/packages/app/src/components/
```

### Paso 2: Modificar App.tsx

Ubicación: `packages/app/src/App.tsx`

```tsx
import { MonitoringPage } from './components/monitoring';
import { GitOpsPage } from './components/gitops';
import { KubernetesPage } from './components/kubernetes';
import { GitHubPage } from './components/github';

// Dentro de <FlatRoutes>
const routes = (
  <FlatRoutes>
    {/* ... rutas existentes ... */}

    {/* Custom Pages */}
    <Route path="/monitoring" element={<MonitoringPage />} />
    <Route path="/gitops" element={<GitOpsPage />} />
    <Route path="/kubernetes" element={<KubernetesPage />} />
    <Route path="/github" element={<GitHubPage />} />

    {/* ... otras rutas ... */}
  </FlatRoutes>
);
```

### Paso 3: Modificar Root.tsx (Sidebar)

Ubicación: `packages/app/src/components/Root/Root.tsx`

```tsx
import MonitoringIcon from '@material-ui/icons/ShowChart';
import GitOpsIcon from '@material-ui/icons/CloudSync';
import KubernetesIcon from '@material-ui/icons/Cloud';
import GitHubIcon from '@material-ui/icons/GitHub';

// Dentro de <SidebarGroup>
export const Root = ({ children }: PropsWithChildren<{}>) => (
  <SidebarPage>
    <Sidebar>
      <SidebarGroup label="Menu" icon={<MenuIcon />}>
        {/* ... items existentes ... */}

        {/* Custom Pages */}
        <SidebarItem
          icon={MonitoringIcon}
          to="monitoring"
          text="Monitoring"
        />
        <SidebarItem
          icon={GitOpsIcon}
          to="gitops"
          text="GitOps"
        />
        <SidebarItem
          icon={KubernetesIcon}
          to="kubernetes"
          text="Kubernetes"
        />
        <SidebarItem
          icon={GitHubIcon}
          to="github"
          text="GitHub"
        />
      </SidebarGroup>
    </Sidebar>
    {children}
  </SidebarPage>
);
```

### Paso 4: Instalar Dependencias (si es necesario)

```bash
cd packages/app
yarn add @material-ui/icons
```

### Paso 5: Build y Deploy

```bash
# Build
yarn build

# Build Docker image
docker build -t backstage-custom:latest .

# Load a Kind
kind load docker-image backstage-custom:latest --name kind

# Update deployment
kubectl set image deployment/backstage \
  backstage=backstage-custom:latest \
  -n backstage

# O aplicar el nuevo deployment
kubectl apply -f kubernetes/custom-deployment.yaml
```

---

## 📝 Notas Importantes

1. **URLs de Servicios**: Las páginas usan iframes apuntando a:
   - Prometheus: `http://prometheus.kind.local`
   - Grafana: `http://grafana.kind.local`
   - ArgoCD: `http://argocd.kind.local`

2. **CORS**: Si hay problemas de CORS, agregar headers en los ingresses:
   ```yaml
   nginx.ingress.kubernetes.io/enable-cors: "true"
   nginx.ingress.kubernetes.io/cors-allow-origin: "http://backstage.kind.local"
   ```

3. **Permisos Kubernetes**: El ServiceAccount `backstage` necesita permisos para:
   - Listar pods, services, deployments
   - Ver namespaces
   - Acceder a métricas

---

## 🎨 Preview de las Páginas

### Monitoring Page
- **Tab 1**: Prometheus (iframe embebido)
- **Tab 2**: Grafana (iframe embebido)
- **Tab 3**: Métricas rápidas (estadísticas)

### GitOps Page
- **Tab 1**: ArgoCD Console
- **Tab 2**: Applications list
- **Tab 3**: Sync status

### Kubernetes Page
- **Tab 1**: Cluster overview
- **Tab 2**: Pods por namespace
- **Tab 3**: Resources y quotas

### GitHub Page
- **Tab 1**: Repositories
- **Tab 2**: Recent workflows
- **Tab 3**: Pull requests

---

## 🚨 Troubleshooting

### Páginas no aparecen en sidebar

Verificar:
```bash
# 1. Routes agregadas en App.tsx
grep -r "MonitoringPage" packages/app/src/App.tsx

# 2. Sidebar items agregados
grep -r "monitoring" packages/app/src/components/Root/Root.tsx

# 3. Rebuild necesario
yarn build
```

### Iframe no carga

Verificar:
```bash
# 1. Servicios accesibles
curl -I http://prometheus.kind.local
curl -I http://grafana.kind.local

# 2. CORS headers en ingress
kubectl describe ingress prometheus -n monitoring | grep cors
```

---

## 📚 Recursos

- [Backstage Custom Pages](https://backstage.io/docs/getting-started/app-custom-theme)
- [Material-UI Icons](https://v4.mui.com/components/material-icons/)
- [React Router](https://reactrouter.com/)

---

**Siguiente Paso**: Ver archivos en `components/` para el código de cada página.
