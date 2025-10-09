# 🚀 Backstage Kind Migration - Fresh Start

**Proyecto**: Migración de Backstage a Kind Cluster desde cero
**Fecha de Inicio**: 3 de Octubre, 2025
**Autor**: Jaime Henao
**Objetivo**: Crear deployment de Backstage en Kind con todas las integraciones

---

## 📁 Estructura del Proyecto

```
backstage-kind-migration/
├── README.md                          # Este archivo
├── docs/                              # Documentación
│   ├── MIGRATION_PLAN.md             # Plan completo de migración
│   ├── CONFIGURATION_GUIDE.md        # Guía de configuración
│   └── TROUBLESHOOTING.md            # Solución de problemas
├── backstage/                         # Código fuente de Backstage (nuevo proyecto)
│   ├── packages/
│   ├── catalog/
│   ├── app-config.yaml
│   └── Dockerfile.production
├── kubernetes/                        # Manifiestos de Kubernetes
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secrets.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── rbac.yaml
├── scripts/                           # Scripts de automatización
│   ├── 01-init-backstage.sh         # Inicializar proyecto Backstage
│   ├── 02-build-image.sh            # Construir imagen Docker
│   ├── 03-deploy-to-kind.sh         # Desplegar en Kind
│   ├── 04-verify-deployment.sh      # Verificar deployment
│   └── 99-cleanup.sh                # Limpieza
└── config/                            # Configuraciones auxiliares
    ├── app-config.kubernetes.yaml    # Config específico de K8s
    └── catalog-entities/             # Entidades del catálogo
```

---

## 🎯 Fases de Migración

### ✅ Fase 0: Setup Inicial (En Progreso)
- [x] Crear estructura de carpetas
- [ ] Documentar plan de migración
- [ ] Preparar scripts de automatización

### 📋 Fase 1: Inicializar Backstage
- [ ] Crear nuevo proyecto Backstage con `npx @backstage/create-app@latest`
- [ ] Instalar plugins necesarios
- [ ] Configurar integrations (GitHub, ArgoCD, etc.)

### 🏗️ Fase 2: Configurar para Kubernetes
- [ ] Crear Dockerfile multi-stage optimizado
- [ ] Configurar app-config.kubernetes.yaml
- [ ] Crear manifiestos de Kubernetes

### 🐳 Fase 3: Build y Deploy
- [ ] Construir imagen Docker
- [ ] Cargar imagen en Kind
- [ ] Desplegar en cluster Kind

### ✅ Fase 4: Testing y Validación
- [ ] Verificar health checks
- [ ] Probar integraciones (Kubernetes, ArgoCD, Grafana)
- [ ] Performance testing

---

## 🚀 Quick Start

### Pre-requisitos
- Node.js 20+
- Docker Desktop
- Kind cluster running
- kubectl configurado

### Paso 1: Inicializar Backstage
```bash
cd /Users/jaime.henao/arheanja/Backstage-solutions/backstage-kind-migration
./scripts/01-init-backstage.sh
```

### Paso 2: Build Image
```bash
./scripts/02-build-image.sh
```

### Paso 3: Deploy to Kind
```bash
./scripts/03-deploy-to-kind.sh
```

### Paso 4: Verificar
```bash
./scripts/04-verify-deployment.sh
```

---

## 🔗 Acceso

Una vez desplegado, acceder a:
- **Backstage UI**: http://backstage.kind.local
- **Health Check**: http://backstage.kind.local/healthcheck
- **Kubernetes**: Integración embebida
- **ArgoCD**: http://argocd.kind.local
- **Grafana**: http://grafana.kind.local

---

## 📚 Recursos

### Documentación Original
- Proyecto Actual: `/Users/jaime.henao/arheanja/Backstage-solutions/backstage-app-devc`
- Configuración: `backstage-app-devc/backstage/app-config.yaml`
- Plugins: `backstage-app-devc/backstage/packages/app/package.json`

### Referencias
- [Backstage Official Docs](https://backstage.io/docs/)
- [Kubernetes Deployment Guide](https://backstage.io/docs/deployment/k8s/)
- [Kind User Guide](https://kind.sigs.k8s.io/)

---

**Status**: 🚧 In Progress - Fase 0

**Next Step**: Ejecutar `./scripts/01-init-backstage.sh`
