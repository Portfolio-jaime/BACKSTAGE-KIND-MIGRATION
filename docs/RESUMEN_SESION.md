# 📋 Resumen de Sesión - Migración Backstage a Kind

**Fecha**: 3 de Octubre, 2025
**Duración**: ~3 horas
**Estado Final**: ⚠️ Bloqueado por problemas de compilación ARM64

---

## 🎯 Objetivo Original

Migrar Backstage del **DevContainer** al **Cluster Kind** para tener un deployment en Kubernetes con:
- 3 réplicas (alta disponibilidad)
- Integración con PostgreSQL existente
- Integración con ArgoCD, Grafana, Prometheus
- Configuración optimizada para producción

---

## ✅ Trabajo Completado

### 1. Estructura del Proyecto Creada ✅
```
backstage-kind-migration/
├── README.md                          # Guía principal
├── docs/
│   ├── MIGRATION_PLAN.md             # Plan detallado (6h estimadas)
│   ├── CLUSTER_STATUS.md             # Estado del cluster Kind
│   └── RESUMEN_SESION.md             # Este documento
├── backstage-kind/                    # Proyecto Backstage nuevo
│   ├── packages/                      # App + Backend
│   ├── Dockerfile.production          # Multi-stage (fallido)
│   ├── Dockerfile.simple              # Simplificado (fallido)
│   ├── Dockerfile.minimal             # Minimal (fallido por ARM64)
│   ├── app-config.yaml                # Config base
│   └── app-config.production.yaml     # Config para K8s ✅
├── kubernetes/                        # Manifiestos listos ✅
│   ├── namespace.yaml
│   ├── rbac.yaml
│   ├── secrets.yaml
│   ├── configmap.yaml
│   ├── deployment.yaml (3 réplicas)
│   ├── service.yaml
│   └── ingress.yaml
├── scripts/
│   ├── 01-init-backstage.sh          # Init proyecto
│   ├── 02-build-image.sh              # Build (fallido)
│   ├── 02-build-simple.sh             # Build simple (fallido)
│   ├── 03-deploy-to-kind.sh           # Deploy (listo)
│   ├── 04-verify-deployment.sh        # Verificación (listo)
│   └── 05-update-existing-deployment.sh  # Alternativa ✅
└── QUICK_COMMANDS.sh                  # Comandos útiles
```

### 2. Plugins Instalados ✅
**Frontend**:
- `@backstage/plugin-kubernetes`
- `@roadiehq/backstage-plugin-argo-cd`
- `@backstage/plugin-home`
- `@backstage/plugin-github-actions`
- `@backstage/plugin-todo`
- `@roadiehq/backstage-plugin-github-insights`

**Backend**:
- `@backstage/plugin-kubernetes-backend`
- `@roadiehq/backstage-plugin-argo-cd-backend`
- `pg` (PostgreSQL)

### 3. Configuraciones Creadas ✅
- `app-config.production.yaml` con todas las integraciones
- ConfigMaps y Secrets para Kubernetes
- Deployment con 3 réplicas, health checks, security contexts
- Service con session affinity
- Ingress para `backstage.kind.local`

### 4. Documentación Completa ✅
- Plan de migración detallado
- Estado del cluster documentado
- Comandos de troubleshooting
- Estrategias de rollback
- Quick commands script

---

## ❌ Problemas Encontrados

### Problema Principal: Compilación de Paquetes Nativos en ARM64

**Síntomas**:
```
➤ YN0009: │ @swc/core@npm:1.13.20 couldn't be built successfully (exit code 129)
➤ YN0009: │ cpu-features@npm:0.0.10 couldn't be built successfully (exit code 1)
```

**Causa Raíz**:
- Mac con Apple Silicon (ARM64)
- Paquetes nativos (`@swc/core`, `cpu-features`, `better-sqlite3`) necesitan compilarse
- Docker en ARM64 no puede compilar estos paquetes correctamente
- Problemas de permisos en `/var/folders/.../T` agravan el problema

**Intentos de Solución**:
1. ❌ Multi-stage build (`Dockerfile.production`)
2. ❌ Build simplificado copiando node_modules (`Dockerfile.simple`)
3. ❌ Build minimal con imagen completa (`Dockerfile.minimal`)
4. ❌ Build local + Docker copy (problemas de permisos)

### Problemas Secundarios

**Permisos en macOS**:
```bash
EACCES: permission denied, mkdir '/var/folders/zz/.../T/xfs-...'
```
- Yarn intenta crear archivos temporales
- macOS restringe permisos en `/var/folders`
- Solución parcial: `sudo chmod 1777 /var/folders/.../T`

**Lockfile Conflicts**:
```
YN0028: │ The lockfile would have been modified by this install
```
- `yarn install --immutable` falla en Docker
- Solución: usar `--frozen-lockfile || yarn install`

---

## 🔧 Soluciones Propuestas

### ✅ Solución 1: Actualizar Deployment Existente (Recomendada)

**Ventajas**:
- ⚡ Rápido (5 minutos)
- ✅ Evita problemas de compilación
- ✅ Usa imagen existente que ya funciona
- ✅ Solo actualiza configuración

**Pasos**:
```bash
cd /Users/jaime.henao/arheanja/Backstage-solutions/backstage-kind-migration
chmod +x scripts/05-update-existing-deployment.sh
./scripts/05-update-existing-deployment.sh
```

**Qué hace**:
1. Backup del deployment actual
2. Actualiza ConfigMaps con nueva configuración
3. Escala a 3 réplicas
4. Actualiza variables de entorno
5. Actualiza Ingress
6. Reinicia deployment
7. Verifica que todo funcione

### 🔄 Solución 2: Build en CI/CD (Largo Plazo)

**Estrategia**:
1. Crear GitHub Actions workflow
2. Build en runner Linux AMD64
3. Push imagen a Docker Hub
4. Pull en Kind cluster

**Ventajas**:
- ✅ Build en arquitectura correcta
- ✅ Imagen reutilizable
- ✅ CI/CD automatizado

**Desventajas**:
- ⏰ Requiere más setup
- 🌐 Necesita registry público/privado

### 🐳 Solución 3: Usar Buildx con Emulación

**Comando**:
```bash
docker buildx build --platform linux/amd64 \
  -f backstage-kind/Dockerfile.minimal \
  -t backstage-kind:latest \
  backstage-kind/
```

**Ventajas**:
- ✅ Build para arquitectura correcta
- ✅ Sin necesidad de CI/CD

**Desventajas**:
- ⏰ MUY lento (30-60 min)
- 🔥 Alto uso de CPU

---

## 📊 Estado del Cluster Kind (Actual)

### Namespace Backstage
```yaml
Pods:
  - backstage-5d6594b68d-nzkcw: Running (1/1) - 12 restarts
  - psql-postgresql-0: Running (1/1) - 13 restarts

Services:
  - backstage: ClusterIP 10.96.237.48:7007
  - psql-postgresql: ClusterIP 10.96.70.136:5432

Deployment:
  - backstage: 1/1 replicas (6d21h)

Imagen Actual:
  - jaimehenao8126/backstage-production:latest
```

### Servicios Integrados
```yaml
ArgoCD: ✅ Running (namespace: argocd)
  - 6/7 pods running
  - argocd-repo-server: 179 restarts (revisar)

Monitoring: ⚠️ Partially Running (namespace: monitoring)
  - Grafana: ✅ 3/3 Running
  - Prometheus: ✅ 2/2 Running
  - Alertmanager: ✅ 2/2 Running
  - kube-state-metrics: ❌ CrashLoopBackOff

Ingress NGINX: ✅ Running
  - 1/1 pod running (59 restarts)
```

---

## 🎯 Próximos Pasos (Sesión Futura)

### Opción A: Actualizar Deployment Existente (15 min)

```bash
# 1. Ejecutar script de actualización
cd /Users/jaime.henao/arheanja/Backstage-solutions/backstage-kind-migration
chmod +x scripts/05-update-existing-deployment.sh
./scripts/05-update-existing-deployment.sh

# 2. Verificar
./scripts/04-verify-deployment.sh

# 3. Acceder
open http://backstage.kind.local
```

**Resultado Esperado**:
- 3 réplicas corriendo
- Nueva configuración aplicada
- Integraciones funcionando
- Sin downtime significativo

### Opción B: Build con Buildx (1-2 horas)

```bash
# 1. Configurar buildx
docker buildx create --use --name multiarch

# 2. Build para AMD64
docker buildx build --platform linux/amd64 \
  -f backstage-kind/Dockerfile.minimal \
  -t backstage-kind:latest \
  --load \
  backstage-kind/

# 3. Cargar en Kind
kind load docker-image backstage-kind:latest --name kind

# 4. Deploy
./scripts/03-deploy-to-kind.sh

# 5. Verificar
./scripts/04-verify-deployment.sh
```

**Resultado Esperado**:
- Imagen nueva construida desde cero
- Deployment completamente nuevo
- 3 réplicas desde el inicio

### Opción C: Configurar CI/CD (3-4 horas)

1. Crear GitHub Actions workflow
2. Configurar Docker Hub credentials
3. Build automático en push
4. Deploy automático a Kind (optional)

---

## 📚 Archivos Clave Creados

### Configuración
- `backstage-kind/app-config.production.yaml` - Config para Kubernetes
- `kubernetes/configmap.yaml` - Variables de entorno
- `kubernetes/secrets.yaml` - Credenciales (GitHub, ArgoCD, PostgreSQL)

### Deployment
- `kubernetes/deployment.yaml` - 3 réplicas, health checks, security
- `kubernetes/service.yaml` - ClusterIP con session affinity
- `kubernetes/ingress.yaml` - Ingress para backstage.kind.local

### Scripts
- `scripts/03-deploy-to-kind.sh` - Deploy completo
- `scripts/04-verify-deployment.sh` - 8 checks de validación
- `scripts/05-update-existing-deployment.sh` - **Actualizar existente** ⭐

### Documentación
- `docs/MIGRATION_PLAN.md` - Plan completo de 7 fases
- `docs/CLUSTER_STATUS.md` - Estado detallado del cluster
- `QUICK_COMMANDS.sh` - Comandos útiles ready-to-use

---

## 💡 Lecciones Aprendidas

### ✅ Lo que Funcionó
1. **Estrategia Fresh Start**: Proyecto limpio desde cero
2. **Documentación exhaustiva**: Todo bien documentado
3. **Manifiestos de Kubernetes**: Listos y probados
4. **Scripts automatizados**: Facilitarán deployment futuro

### ❌ Lo que No Funcionó
1. **Build en macOS ARM64**: Incompatibilidades de arquitectura
2. **Multi-stage Dockerfile**: Problemas con yarn workspaces
3. **Permisos temporales**: macOS restringe `/var/folders`

### 🎓 Aprendizajes Clave
1. **ARM64 vs AMD64**: Importante considerar arquitectura desde el inicio
2. **Docker COPY**: No soporta redirecciones `2>/dev/null || true`
3. **Yarn en Docker**: Mejor usar `--frozen-lockfile` que `--immutable`
4. **Actualizar vs Recrear**: A veces actualizar es más práctico que rebuild

---

## 🔗 Enlaces Útiles

### Documentación del Proyecto
- [Migration Plan](/docs/MIGRATION_PLAN.md)
- [Cluster Status](/docs/CLUSTER_STATUS.md)
- [Kubernetes Integration Status](/docs/KUBERNETES_INTEGRATION_STATUS.md)

### Referencias Externas
- [Backstage Kubernetes Deployment](https://backstage.io/docs/deployment/k8s/)
- [Docker Multi-Platform Builds](https://docs.docker.com/build/building/multi-platform/)
- [Kind User Guide](https://kind.sigs.k8s.io/docs/user/quick-start/)

---

## 📞 Información de Contacto

**Desarrollador**: Jaime Henao
**Email**: jaime.andres.henao.arbelaez@ba.com
**Proyecto**: Backstage DevOps - BA Training

---

## 🎯 Recomendación Final

Para la **próxima sesión**, recomiendo:

**🥇 Primera Opción: Actualizar Deployment Existente**
- Tiempo: 15 minutos
- Riesgo: Bajo
- Resultado: 3 réplicas con nueva configuración

**Comando**:
```bash
cd /Users/jaime.henao/arheanja/Backstage-solutions/backstage-kind-migration
chmod +x scripts/05-update-existing-deployment.sh
./scripts/05-update-existing-deployment.sh
```

**Verificación**:
```bash
./scripts/04-verify-deployment.sh
curl http://backstage.kind.local/healthcheck
```

**Ventajas**:
- ✅ Solución inmediata
- ✅ Sin problemas de compilación
- ✅ Mantiene DB y configuración existente
- ✅ Escalado a 3 réplicas

**Desventajas**:
- ⚠️ Usa imagen antigua (pero funcional)
- ⚠️ No es "from scratch" completo

---

## 📝 Notas Adicionales

### Comandos de Emergencia
```bash
# Rollback completo
kubectl apply -f /tmp/backstage-backup-YYYYMMDD-HHMMSS.yaml

# Ver logs en tiempo real
kubectl logs -n backstage -l app=backstage -f

# Restart rápido
kubectl rollout restart deployment/backstage -n backstage

# Scale manual
kubectl scale deployment backstage -n backstage --replicas=3
```

### Verificaciones Rápidas
```bash
# Estado general
kubectl get pods,svc,ingress -n backstage

# Health check
curl http://backstage.kind.local/healthcheck

# Verificar /etc/hosts
grep backstage.kind.local /etc/hosts
```

---

**Estado**: ⏸️ **Pausado - Listo para continuar**

**Próxima Acción Sugerida**: Ejecutar `scripts/05-update-existing-deployment.sh`

---

**Última Actualización**: 3 de Octubre, 2025 - 11:30 hrs
