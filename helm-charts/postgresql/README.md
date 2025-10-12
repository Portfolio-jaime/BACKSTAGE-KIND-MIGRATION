# 🐘 PostgreSQL para Backstage

Base de datos PostgreSQL desplegada con Bitnami Helm chart y gestionada por ArgoCD.

## 📋 Características

- **Version**: PostgreSQL 17.6.0
- **Helm Chart**: Bitnami PostgreSQL 16.7.27
- **Architecture**: Standalone (single instance)
- **Persistent Storage**: 8Gi (expandible)
- **Metrics**: Prometheus ServiceMonitor habilitado
- **Recursos**: CPU 100m-500m, Memoria 256Mi-512Mi

## 🚀 Despliegue

### Prerequisitos

1. **Secret de credenciales** (se crea automáticamente si no existe):
```bash
kubectl create secret generic backstage-postgres-secrets -n backstage \
  --from-literal=postgres-password=backstage \
  --from-literal=password=backstage
```

2. **ArgoCD** instalado y configurado

### Desplegar con ArgoCD

```bash
kubectl apply -f argocd/postgresql-application.yaml
```

Esto desplegará:
- PostgreSQL StatefulSet (1 replica)
- PVC de 8Gi para datos
- Services (ClusterIP + Headless)
- ServiceMonitor para Prometheus
- Secret con credenciales

**Tiempo de despliegue**: ~2-3 minutos

### Verificar Despliegue

```bash
# Ver estado del pod
kubectl get pods -n backstage | grep psql

# Ver PVC
kubectl get pvc -n backstage | grep psql

# Ver servicios
kubectl get svc -n backstage | grep psql

# Test de conexión
kubectl run psql-test --rm -it --image=postgres:17 --command -n backstage -- \
  psql -h psql-postgresql -U backstage -d backstage -c "SELECT version();"
```

## ⚙️ Configuración

### Values.yaml Principal

Ubicación: `helm-charts/postgresql/values.yaml`

**Highlights**:

```yaml
# Persistent storage
primary:
  persistence:
    enabled: true
    size: 8Gi

# Resources
primary:
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi

# Metrics
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
```

### Configuración de PostgreSQL

PostgreSQL está configurado con:

```sql
-- Parámetros optimizados para Backstage
max_connections = 100
shared_buffers = 128MB
effective_cache_size = 256MB
wal_level = replica
max_wal_size = 1GB
```

### Extensiones Instaladas

Extensiones creadas automáticamente en init:

```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
```

## 🔗 Conexión desde Backstage

### Variables de Entorno

El secret `backstage-postgres-secrets` contiene:

```yaml
POSTGRES_HOST: psql-postgresql
POSTGRES_PORT: "5432"
POSTGRES_USER: backstage
password: backstage
postgres-password: backstage
```

### Connection String

```
postgresql://backstage:backstage@psql-postgresql:5432/backstage
```

### En app-config.yaml de Backstage

```yaml
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

## 📊 Monitoreo

### ServiceMonitor

PostgreSQL expone métricas para Prometheus:

```yaml
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: backstage
```

### Métricas Disponibles

- `pg_up` - PostgreSQL is up
- `pg_stat_database_*` - Database statistics
- `pg_stat_bgwriter_*` - Background writer stats
- `pg_locks_*` - Lock information
- `pg_connections_*` - Connection metrics

### Queries de Prometheus

```promql
# PostgreSQL is up
pg_up{namespace="backstage"}

# Conexiones activas
pg_stat_database_numbackends{namespace="backstage"}

# Tamaño de la base de datos
pg_database_size_bytes{namespace="backstage",datname="backstage"}

# Transacciones por segundo
rate(pg_stat_database_xact_commit{namespace="backstage"}[5m])
```

## 🔄 Actualizar Configuración

### Flujo GitOps

1. **Modificar values.yaml**:
```bash
vim helm-charts/postgresql/values.yaml
```

2. **Commit y push**:
```bash
git add helm-charts/postgresql/values.yaml
git commit -m "feat: actualizar configuración de PostgreSQL"
git push origin main
```

3. **ArgoCD sincroniza automáticamente**

### Ejemplos de Cambios

#### Aumentar Storage

```yaml
primary:
  persistence:
    size: 16Gi  # Cambiar de 8Gi a 16Gi
```

⚠️ **Nota**: Ampliar storage requiere que el PVC soporte expansión y puede necesitar reiniciar el pod.

#### Aumentar Recursos

```yaml
primary:
  resources:
    requests:
      cpu: 200m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 1Gi
```

#### Cambiar max_connections

```yaml
primary:
  configuration: |-
    max_connections = 200  # Cambiar de 100 a 200
    shared_buffers = 256MB  # Ajustar proporcionalmente
```

## 💾 Backup y Restore

### Backup Manual

```bash
# Backup completo
kubectl exec -n backstage psql-postgresql-0 -- \
  pg_dumpall -U postgres > backup-$(date +%Y%m%d).sql

# Backup de una sola base de datos
kubectl exec -n backstage psql-postgresql-0 -- \
  pg_dump -U backstage backstage > backstage-$(date +%Y%m%d).sql
```

### Restore

```bash
# Restore completo
cat backup-20250101.sql | \
  kubectl exec -i -n backstage psql-postgresql-0 -- \
  psql -U postgres

# Restore de una base de datos
cat backstage-20250101.sql | \
  kubectl exec -i -n backstage psql-postgresql-0 -- \
  psql -U backstage -d backstage
```

### Backup Automático (Opcional)

Habilitar en values.yaml:

```yaml
backup:
  enabled: true
  cronjob:
    schedule: "0 2 * * *"  # 2 AM diario
    storage: 10Gi
```

## 🛠️ Operaciones Comunes

### Conectarse al Pod

```bash
kubectl exec -it -n backstage psql-postgresql-0 -- bash
```

### Conectarse a PostgreSQL

```bash
kubectl exec -it -n backstage psql-postgresql-0 -- \
  psql -U backstage -d backstage
```

### Ver Logs

```bash
kubectl logs -n backstage psql-postgresql-0 -f
```

### Reiniciar PostgreSQL

```bash
kubectl rollout restart statefulset/psql-postgresql -n backstage
```

### Ver Configuración Actual

```bash
kubectl exec -n backstage psql-postgresql-0 -- \
  psql -U postgres -c "SHOW ALL;"
```

### Ver Bases de Datos

```bash
kubectl exec -n backstage psql-postgresql-0 -- \
  psql -U postgres -c "\l"
```

### Ver Tamaño de Base de Datos

```bash
kubectl exec -n backstage psql-postgresql-0 -- \
  psql -U backstage -d backstage -c \
  "SELECT pg_size_pretty(pg_database_size('backstage'));"
```

## 🔧 Troubleshooting

### Pod no inicia

```bash
# Ver logs
kubectl logs -n backstage psql-postgresql-0

# Ver eventos
kubectl describe pod -n backstage psql-postgresql-0

# Verificar PVC
kubectl get pvc -n backstage | grep psql
```

### Errores de conexión

```bash
# Test de conexión desde otro pod
kubectl run psql-test --rm -it --image=postgres:17 -n backstage -- \
  psql -h psql-postgresql -U backstage -d backstage

# Verificar servicio
kubectl get svc -n backstage psql-postgresql
kubectl get endpoints -n backstage psql-postgresql
```

### Out of Memory

```bash
# Ver uso de memoria
kubectl top pod -n backstage psql-postgresql-0

# Aumentar límites en values.yaml
primary:
  resources:
    limits:
      memory: 1Gi
```

### Persistent Volume Full

```bash
# Ver uso de disco
kubectl exec -n backstage psql-postgresql-0 -- df -h

# Ver tamaño de datos
kubectl exec -n backstage psql-postgresql-0 -- \
  du -sh /bitnami/postgresql/data

# Ampliar PVC (si StorageClass lo soporta)
kubectl patch pvc data-psql-postgresql-0 -n backstage \
  -p '{"spec":{"resources":{"requests":{"storage":"16Gi"}}}}'
```

## 📚 Referencias

- [Bitnami PostgreSQL Chart](https://github.com/bitnami/charts/tree/main/bitnami/postgresql)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/17/)
- [Backstage Database Setup](https://backstage.io/docs/getting-started/config/database)

---

**Maintainer**: Jaime Henao <jaime.andres.henao.arbelaez@ba.com>
**Última actualización**: Octubre 11, 2025
**Status**: ✅ Gestionado por GitOps con ArgoCD
