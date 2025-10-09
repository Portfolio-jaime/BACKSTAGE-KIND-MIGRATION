# 📊 Kind Cluster Status - Pre-Migration

**Fecha**: 3 de Octubre, 2025
**Cluster**: kind-kind (local)

---

## 🎯 Estado Actual del Cluster

### ✅ Namespaces Disponibles
```
backstage               ✅ Active (7d21h) - Destino de la migración
argocd                  ✅ Active (19d)
monitoring              ✅ Active (3d4h) - Grafana + Prometheus
ingress-nginx           ✅ Active (20d)
cert-manager            ✅ Active (19d)
actions-runner-system   ✅ Active (19d)
```

### 🔍 Namespace Backstage (Actual)

#### Pods
```
backstage-5d6594b68d-nzkcw    1/1 Running   12 restarts   3d23h
psql-postgresql-0             1/1 Running   13 restarts   6d19h
```

#### Services
```
backstage              ClusterIP   10.96.237.48    7007/TCP
psql-postgresql        ClusterIP   10.96.70.136    5432/TCP
psql-postgresql-hl     ClusterIP   None            5432/TCP
```

#### Deployment
```
backstage              1/1 replicas   Available   6d21h
```

**⚠️ Importante**: PostgreSQL ya existe y está funcionando. Reutilizaremos este servicio.

### 🌐 Servicios Integrados

#### ArgoCD
```
Status: ✅ Running
Namespace: argocd
Pods: 6/7 running
  - argocd-server: Running (con algunas issues)
  - argocd-repo-server: Running (179 restarts - revisar)
```

#### Monitoring Stack
```
Status: ⚠️ Partially Running
Namespace: monitoring
Components:
  ✅ Grafana:      3/3 Running
  ✅ Prometheus:   2/2 Running
  ✅ Alertmanager: 2/2 Running
  ❌ kube-state-metrics: CrashLoopBackOff (revisar)
  ⚠️ node-exporter: Running (42 restarts)
```

#### Ingress Controller
```
Status: ✅ Running
Namespace: ingress-nginx
Controller: 1/1 Running (59 restarts)
```

---

## 🚀 Plan de Migración

### Estrategia de Deployment

**Opción 1: Zero Downtime (Recomendada)**
1. Mantener deployment actual corriendo
2. Crear nuevo deployment con nombre temporal (`backstage-new`)
3. Probar nuevo deployment
4. Switch de tráfico del ingress
5. Eliminar deployment antiguo

**Opción 2: Replace (Más Simple)**
1. Escalar deployment actual a 0 réplicas
2. Aplicar nuevo deployment (3 réplicas)
3. Verificar health
4. Eliminar deployment antiguo si todo funciona

**Vamos con Opción 2** por simplicidad y porque no es producción crítica.

### Recursos a Mantener
```yaml
✅ Namespace: backstage (no recrear)
✅ PostgreSQL: psql-postgresql (StatefulSet + Services)
✅ RBAC: ServiceAccount backstage (si existe)
❌ Deployment: backstage (reemplazar)
❌ ConfigMaps: (limpiar y recrear)
❌ Ingress: (actualizar si es necesario)
```

---

## 📝 Comandos Útiles Pre-Deploy

### Verificar Estado Actual
```bash
# Ver todos los recursos en backstage
kubectl get all,cm,secret,ingress -n backstage

# Ver logs del backstage actual
kubectl logs -n backstage deployment/backstage --tail=50

# Ver configuración del deployment actual
kubectl get deployment backstage -n backstage -o yaml > /tmp/backstage-old-deployment.yaml

# Ver imagen actual
kubectl get deployment backstage -n backstage -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### Backup Pre-Migration
```bash
# Backup completo del namespace
kubectl get all,cm,secret,ingress,sa,role,rolebinding -n backstage -o yaml > /tmp/backstage-backup-$(date +%Y%m%d-%H%M%S).yaml

# Backup de PostgreSQL
kubectl exec -n backstage psql-postgresql-0 -- pg_dump -U postgres backstage > /tmp/backstage-db-$(date +%Y%m%d-%H%M%S).sql

# Verificar backup
ls -lh /tmp/backstage-*
```

### Verificar PostgreSQL
```bash
# Test de conexión desde un pod temporal
kubectl run test-pg --image=postgres:15 --rm -it --restart=Never -n backstage -- \
  psql -h psql-postgresql.backstage.svc.cluster.local -U postgres -d backstage -c "SELECT version();"

# Ver secrets de PostgreSQL
kubectl get secret -n backstage | grep postgres

# Ver variables del deployment actual
kubectl get deployment backstage -n backstage -o jsonpath='{.spec.template.spec.containers[0].env}' | jq
```

---

## 🔧 Comandos de Deployment

### Pre-Deployment Cleanup
```bash
# Escalar deployment actual a 0 (sin eliminar)
kubectl scale deployment backstage -n backstage --replicas=0

# Verificar que no hay pods corriendo
kubectl get pods -n backstage -l app=backstage

# Eliminar ConfigMaps antiguos (excepto kube-root-ca.crt)
kubectl delete cm -n backstage backstage-base-config backstage-config backstage-enhanced-config backstage-minimal-config 2>/dev/null || true

# Eliminar ingresses antiguos si existen
kubectl delete ingress backstage backstage-enhanced -n backstage 2>/dev/null || true
```

### Deployment del Nuevo Backstage
```bash
cd /Users/jaime.henao/arheanja/Backstage-solutions/backstage-kind-migration

# Ejecutar script de deploy
./scripts/03-deploy-to-kind.sh

# O manual:
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/rbac.yaml
kubectl apply -f kubernetes/secrets.yaml
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/ingress.yaml

# Esperar a que esté listo
kubectl rollout status deployment/backstage -n backstage --timeout=5m
```

### Post-Deployment Verification
```bash
# Ver estado de los pods
kubectl get pods -n backstage -l app=backstage

# Ver logs en tiempo real
kubectl logs -n backstage -l app=backstage -f

# Health check interno
kubectl exec -n backstage deployment/backstage -- curl -f http://localhost:7007/healthcheck

# Health check externo
curl -v http://backstage.kind.local/healthcheck

# Verificar endpoints del service
kubectl get endpoints backstage -n backstage

# Ver eventos recientes
kubectl get events -n backstage --sort-by='.lastTimestamp' | tail -20
```

---

## 🐛 Troubleshooting Commands

### Si los Pods no arrancan
```bash
# Ver estado detallado del pod
kubectl describe pod -n backstage -l app=backstage

# Ver logs del pod (incluso si crasheó)
kubectl logs -n backstage -l app=backstage --previous

# Ver eventos del namespace
kubectl get events -n backstage --field-selector type=Warning

# Verificar imagen está en Kind
docker exec kind-control-plane crictl images | grep backstage-kind
```

### Si falla la conexión a PostgreSQL
```bash
# Verificar que PostgreSQL está corriendo
kubectl get pods -n backstage psql-postgresql-0

# Test de conectividad
kubectl exec -n backstage deployment/backstage -- nc -zv psql-postgresql.backstage.svc.cluster.local 5432

# Ver logs de PostgreSQL
kubectl logs -n backstage psql-postgresql-0 --tail=50

# Verificar secrets
kubectl get secret backstage-secrets -n backstage -o yaml

# Ver variables de entorno del pod
kubectl exec -n backstage deployment/backstage -- env | grep POSTGRES
```

### Si el Ingress no funciona
```bash
# Verificar ingress configuration
kubectl describe ingress backstage -n backstage

# Ver logs del ingress controller
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail=50

# Test de conectividad al service
kubectl run test-curl --image=curlimages/curl:latest --rm -it --restart=Never -n backstage -- \
  curl -v http://backstage.backstage.svc.cluster.local/healthcheck

# Verificar /etc/hosts
cat /etc/hosts | grep backstage.kind.local
```

### Comandos de Diagnóstico Rápido
```bash
# Status completo de un vistazo
kubectl get pods,svc,ingress,cm -n backstage

# Top de recursos (requiere metrics-server)
kubectl top pod -n backstage

# Ver todas las etiquetas
kubectl get pods -n backstage --show-labels

# Exec interactivo en el pod
kubectl exec -it -n backstage deployment/backstage -- /bin/bash

# Port-forward para debug (bypass ingress)
kubectl port-forward -n backstage svc/backstage 7007:80
# Luego: curl http://localhost:7007/healthcheck
```

---

## 🔄 Rollback Plan

### Si el nuevo deployment falla

**Opción 1: Volver al deployment anterior**
```bash
# Si aún existe el deployment viejo (solo escalado a 0)
kubectl scale deployment backstage -n backstage --replicas=1

# Restaurar ingress antiguo si se eliminó
kubectl apply -f /tmp/backstage-old-deployment.yaml
```

**Opción 2: Restaurar desde backup**
```bash
# Restaurar todo el namespace
kubectl apply -f /tmp/backstage-backup-YYYYMMDD-HHMMSS.yaml
```

**Opción 3: Restaurar base de datos (solo si se corrompió)**
```bash
# Escalar Backstage a 0
kubectl scale deployment backstage -n backstage --replicas=0

# Restaurar DB
kubectl exec -i -n backstage psql-postgresql-0 -- psql -U postgres backstage < /tmp/backstage-db-YYYYMMDD-HHMMSS.sql

# Reiniciar Backstage
kubectl scale deployment backstage -n backstage --replicas=3
```

---

## 📊 Monitoreo Post-Migration

### Métricas a Vigilar
```bash
# CPU y Memoria de los pods
watch -n 5 'kubectl top pod -n backstage -l app=backstage'

# Número de restarts
watch -n 10 'kubectl get pods -n backstage -l app=backstage'

# Logs en tiempo real con timestamp
kubectl logs -n backstage -l app=backstage -f --timestamps

# Events en tiempo real
watch -n 5 'kubectl get events -n backstage --sort-by=.lastTimestamp | tail -10'
```

### Health Checks Continuos
```bash
# Script de monitoreo
while true; do
  echo "$(date): Testing health..."
  curl -s http://backstage.kind.local/healthcheck || echo "FAILED"
  sleep 5
done

# Verificar latencia
time curl -s http://backstage.kind.local/healthcheck

# Verificar múltiples endpoints
for endpoint in /healthcheck /catalog /api/docs; do
  echo "Testing $endpoint..."
  curl -s -o /dev/null -w "%{http_code}" http://backstage.kind.local$endpoint
  echo ""
done
```

---

## 🎯 Success Criteria

### ✅ Deployment Exitoso Si:
- [ ] 3 pods en estado **Running**
- [ ] Health check responde **200 OK**
- [ ] Acceso externo via ingress funciona
- [ ] PostgreSQL conectado sin errores
- [ ] Catalog carga componentes
- [ ] Integración Kubernetes funciona
- [ ] Integración ArgoCD funciona
- [ ] No hay restarts continuos (max 1-2 al inicio)
- [ ] Logs sin errores críticos
- [ ] Response time < 2 segundos

### ⚠️ Issues Conocidos a Ignorar
- Warnings de peer dependencies en build
- 1-2 restarts iniciales mientras carga
- Warnings de kube-state-metrics en monitoring namespace (issue separado)

---

## 📞 Comandos de Emergencia

### Detener Todo
```bash
kubectl scale deployment backstage -n backstage --replicas=0
```

### Reiniciar Todo
```bash
kubectl rollout restart deployment/backstage -n backstage
```

### Eliminar y Empezar de Cero
```bash
# PELIGRO: Solo si necesitas empezar desde cero
kubectl delete deployment backstage -n backstage
kubectl delete cm -n backstage --all
kubectl delete ingress -n backstage --all

# Luego volver a aplicar manifiestos
./scripts/03-deploy-to-kind.sh
```

### Ver TODO el output de un pod
```bash
kubectl logs -n backstage POD_NAME --all-containers=true
```

---

**Status**: 📋 Ready for Migration
**Next**: Wait for Docker build to complete, then execute deployment
