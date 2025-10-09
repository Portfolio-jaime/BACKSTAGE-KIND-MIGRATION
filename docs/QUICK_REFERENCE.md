# ⚡ Backstage on Kind - Quick Reference Guide

## 📚 Table of Contents

- [Command Reference](#-command-reference)
- [Troubleshooting Matrix](#-troubleshooting-matrix)
- [Configuration Reference](#-configuration-reference)
- [Resource Specifications](#-resource-specifications)

---

## 🎯 Command Reference

### Build Commands

| Command | Description | Time | Output |
|---------|-------------|------|--------|
| `make build-backend` | 🔨 Compile TypeScript backend | ~45s | `packages/backend/dist/` |
| `make build-frontend` | 🎨 Compile React frontend | ~60s | `packages/app/dist/` |
| `make build` | 🏗️ Build backend + frontend | ~2min | Both dist folders |
| `make build-docker` | 🐳 Create Docker image | ~8min | Docker image (800MB) |
| `make push-docker` | ⬆️ Build + push to DockerHub | ~12min | Image in registry |
| `make clean` | 🧹 Remove build artifacts | ~5s | Clean workspace |

### Deployment Commands

| Command | Description | Time | Result |
|---------|-------------|------|--------|
| `make deploy` | 🚀 Deploy with kubectl | ~2min | Pods running |
| `make helm-install` | ⛵ Install with Helm | ~5min | Helm release created |
| `make helm-upgrade` | 🔄 Upgrade Helm release | ~3min | Release updated |
| `make helm-uninstall` | 🗑️ Remove Helm release | ~30s | Release deleted |
| `make restart` | 🔄 Restart Backstage pods | ~60s | New pods created |
| `make postgres-rollout` | 🔄 Restart PostgreSQL | ~2min | Database restarted |

### Operational Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `make logs` | 📋 View Backstage logs | Debug application |
| `make logs-postgres` | 📋 View PostgreSQL logs | Debug database |
| `make port-forward` | 🔌 Forward to localhost:7007 | Local access |
| `make status` | 📊 Show deployment status | Health check |
| `make describe` | 🔍 Detailed resource info | Deep inspection |
| `make test` | ✅ Test health endpoint | Verify deployment |

### Development Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `make install-deps` | 📦 Install yarn dependencies | Initial setup |
| `make dev` | 🛠️ Run in development mode | Local development |
| `make quick-deploy` | ⚡ Build + restart (no push) | Fast iteration |
| `make prod-deploy` | 🚢 Full production deploy | Production release |

### Direct kubectl Commands

```bash
# Pods
kubectl get pods -n backstage
kubectl describe pod <pod-name> -n backstage
kubectl logs -f <pod-name> -n backstage
kubectl exec -it <pod-name> -n backstage -- /bin/sh

# Services
kubectl get svc -n backstage
kubectl port-forward -n backstage svc/backstage 7007:80

# Deployments
kubectl get deployments -n backstage
kubectl rollout status deployment/backstage -n backstage
kubectl rollout restart deployment/backstage -n backstage

# ConfigMaps & Secrets
kubectl get configmap -n backstage
kubectl get secret -n backstage
kubectl describe configmap backstage-env-config -n backstage

# Events
kubectl get events -n backstage --sort-by='.lastTimestamp'

# Resource usage
kubectl top pods -n backstage
kubectl top nodes
```

### Direct Helm Commands

```bash
# List releases
helm list -n backstage

# Get values
helm get values backstage -n backstage

# Show manifest
helm get manifest backstage -n backstage

# Rollback
helm rollback backstage 1 -n backstage

# History
helm history backstage -n backstage

# Template (dry-run)
helm template backstage helm/backstage --debug
```

---

## 🔧 Troubleshooting Matrix

### Pod Status Issues

| Symptom | Possible Cause | Solution | Command |
|---------|---------------|----------|---------|
| `Pending` | Resource constraints | Check node resources | `kubectl describe node` |
| `Pending` | PVC not bound | Check storage class | `kubectl get pvc -n backstage` |
| `ContainerCreating` | Pulling image | Wait or check image | `kubectl describe pod <name>` |
| `ImagePullBackOff` | Image not found | Verify image exists | `docker pull <image>` |
| `CrashLoopBackOff` | App crashes on start | Check logs | `make logs` |
| `Error` | Container failed | Check exit code | `kubectl describe pod <name>` |
| `OOMKilled` | Out of memory | Increase memory limit | Edit `values.yaml` |
| `Evicted` | Node pressure | Check node resources | `kubectl describe node` |

### Application Errors

| Error Message | Cause | Solution |
|--------------|-------|----------|
| `MODULE_NOT_FOUND` | Missing dependencies | Rebuild Docker image with `make build-docker` |
| `ECONNREFUSED` (5432) | PostgreSQL not ready | Wait or check `kubectl get pods \| grep psql` |
| `ECONNREFUSED` (7007) | App not started | Check health probes in logs |
| `UnauthorizedError` | GitHub token missing | Check secrets: `kubectl get secret backstage-secrets` |
| `Database connection error` | Wrong DB credentials | Verify secret values |
| `Port already in use` | Port-forward active | Kill existing port-forward |

### Build Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `permission denied: /var/folders/` | macOS temp directory | `export TMPDIR=/tmp` |
| `yarn cache owned by root` | Sudo was used | `sudo chown -R $USER:staff ~/.yarn` |
| `Docker build failed` | Out of disk space | Clean: `docker system prune -a` |
| `No space left on device` | Disk full | Check: `df -h` |
| `network timeout` during install | Network issue | Retry or check connection |

### Kubernetes Resource Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `failed quota: backstage-quota` | Resource quota exceeded | `kubectl delete resourcequota -n backstage` |
| `Insufficient memory` | Not enough RAM | Reduce replica count or increase node |
| `Insufficient CPU` | Not enough CPU | Reduce CPU requests |
| `PersistentVolumeClaim is not bound` | No storage available | Check storage class provisioner |
| `Services "backstage" not found` | Service not created | `kubectl apply -f kubernetes/service.yaml` |

### Network & Ingress Issues

| Issue | Check | Solution |
|-------|-------|----------|
| Can't access via Ingress | Ingress class installed? | `kubectl get ingressclass` |
| TLS certificate error | Cert-manager running? | `kubectl get pods -n cert-manager` |
| 502 Bad Gateway | Backend not ready | Check pod status and logs |
| Connection timeout | Service exists? | `kubectl get svc -n backstage` |
| DNS not resolving | CoreDNS running? | `kubectl get pods -n kube-system` |

---

## ⚙️ Configuration Reference

### Environment Variables

#### ConfigMap: `backstage-env-config`

```yaml
# Application
NODE_ENV: production
NODE_OPTIONS: "--max-old-space-size=1024"

# Database
POSTGRES_HOST: psql-postgresql.backstage.svc.cluster.local
POSTGRES_PORT: "5432"
POSTGRES_DB: backstage_plugin_catalog

# Backend
BACKEND_URL: https://backstage.arhean.com
FRONTEND_URL: https://backstage.arhean.com

# Logging
LOG_LEVEL: info
```

#### Secret: `backstage-secrets`

```yaml
# Database credentials
POSTGRES_USER: <base64-encoded>
POSTGRES_PASSWORD: <base64-encoded>

# GitHub integration
GITHUB_TOKEN: <base64-encoded>
GITHUB_CLIENT_ID: <base64-encoded>
GITHUB_CLIENT_SECRET: <base64-encoded>
```

**Encode/Decode secrets:**
```bash
# Encode
echo -n "my-secret-value" | base64

# Decode
echo "bXktc2VjcmV0LXZhbHVl" | base64 -d
```

**Update secret:**
```bash
kubectl edit secret backstage-secrets -n backstage
# Then restart: make restart
```

### Health Check Configuration

```yaml
# Startup Probe (allows 2 minutes for startup)
initialDelaySeconds: 30    # Wait 30s before first check
periodSeconds: 10          # Check every 10s
timeoutSeconds: 5          # Wait 5s for response
failureThreshold: 12       # Fail after 12 failures (2 min total)

# Liveness Probe (is app alive?)
initialDelaySeconds: 90    # Wait 90s after startup
periodSeconds: 30          # Check every 30s
timeoutSeconds: 10         # Wait 10s for response
failureThreshold: 3        # Restart after 3 failures

# Readiness Probe (is app ready for traffic?)
initialDelaySeconds: 60    # Wait 60s after startup
periodSeconds: 10          # Check every 10s
timeoutSeconds: 5          # Wait 5s for response
failureThreshold: 3        # Remove from service after 3 failures
```

### Resource Limits

#### Backstage Pod

```yaml
resources:
  requests:          # Minimum guaranteed
    memory: "512Mi"  # 512 MiB
    cpu: "250m"      # 0.25 CPU cores
  limits:            # Maximum allowed
    memory: "2Gi"    # 2 GiB
    cpu: "1000m"     # 1 CPU core
```

#### Init Container

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "128Mi"
    cpu: "100m"
```

#### PostgreSQL (if using official chart)

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

### Storage Configuration

```yaml
# Temporary volumes (emptyDir)
volumes:
  tmp:
    sizeLimit: 1Gi      # /tmp mount
  appTmp:
    sizeLimit: 1Gi      # /app/tmp mount

# PostgreSQL persistent volume
persistentVolume:
  size: 8Gi
  storageClass: standard  # or hostpath for Kind
  accessModes:
    - ReadWriteOnce
```

---

## 📊 Resource Specifications

### Deployment Specs

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backstage
  namespace: backstage
spec:
  replicas: 1
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: backstage
```

### Service Specs

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backstage
  namespace: backstage
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 7007
      protocol: TCP
  selector:
    app: backstage
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800  # 3 hours
```

### Ingress Specs

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: backstage
  namespace: backstage
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/ssl-protocols: "TLSv1.2 TLSv1.3"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - backstage.arhean.com
      secretName: backstage-tls
  rules:
    - host: backstage.arhean.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: backstage
                port:
                  number: 80
```

---

## 🔐 Security Specifications

### Pod Security Context

```yaml
securityContext:
  fsGroup: 1000                    # Files owned by group 1000
  seccompProfile:
    type: RuntimeDefault           # Default seccomp profile
```

### Container Security Context

```yaml
securityContext:
  runAsNonRoot: true               # Cannot run as root
  runAsUser: 1000                  # Run as user 1000
  allowPrivilegeEscalation: false  # No privilege escalation
  readOnlyRootFilesystem: false    # Root FS is writable
  capabilities:
    drop:
      - ALL                        # Drop all capabilities
```

### RBAC Permissions

```yaml
# ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backstage
  namespace: backstage

---
# ClusterRole (read-only access)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: backstage-backend
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]

---
# ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: backstage-backend
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: backstage-backend
subjects:
  - kind: ServiceAccount
    name: backstage
    namespace: backstage
```

---

## 📈 Monitoring Specs

### Prometheus Annotations

```yaml
annotations:
  prometheus.io/scrape: "true"     # Enable scraping
  prometheus.io/port: "7007"       # Scrape port
  prometheus.io/path: "/metrics"   # Metrics endpoint
```

### Available Endpoints

| Endpoint | Purpose | Expected Response |
|----------|---------|-------------------|
| `/healthcheck` | Application health | `{"status":"ok"}` |
| `/metrics` | Prometheus metrics | Text format metrics |
| `/api/app/metrics` | App-specific metrics | JSON metrics |

### Example Metrics Query

```bash
# Application metrics
curl http://localhost:7007/metrics

# Sample output:
# process_cpu_user_seconds_total 1.23
# process_cpu_system_seconds_total 0.45
# nodejs_heap_size_total_bytes 123456789
# http_request_duration_seconds_bucket{...} 0.001
```

---

## 🎯 Quick Troubleshooting Workflows

### Workflow 1: Pod Won't Start

```bash
# 1. Check pod status
kubectl get pods -n backstage

# 2. Describe pod (look for events)
kubectl describe pod <pod-name> -n backstage

# 3. Check logs
kubectl logs <pod-name> -n backstage

# 4. Check previous crash (if restarted)
kubectl logs <pod-name> -n backstage --previous

# 5. Common fixes:
# - If ImagePullBackOff: make push-docker
# - If CrashLoopBackOff: Check logs for error
# - If Pending: kubectl describe node
```

### Workflow 2: Application Error

```bash
# 1. View live logs
make logs

# 2. Check health
make port-forward
curl http://localhost:7007/healthcheck

# 3. Verify database connection
kubectl exec -it -n backstage <pod-name> -- \
  nc -zv psql-postgresql.backstage.svc.cluster.local 5432

# 4. Check configuration
kubectl get configmap backstage-env-config -n backstage -o yaml
kubectl get secret backstage-secrets -n backstage -o yaml

# 5. Restart if needed
make restart
```

### Workflow 3: Database Issues

```bash
# 1. Check PostgreSQL pod
kubectl get pods -n backstage | grep psql

# 2. View PostgreSQL logs
make logs-postgres

# 3. Test connectivity from Backstage pod
kubectl exec -it -n backstage <backstage-pod> -- \
  nc -zv psql-postgresql.backstage.svc.cluster.local 5432

# 4. Check PVC
kubectl get pvc -n backstage

# 5. Restart if needed
make postgres-rollout
```

---

## 📱 Quick Access URLs

| Service | URL | Notes |
|---------|-----|-------|
| **Local (port-forward)** | http://localhost:7007 | Run `make port-forward` first |
| **Production** | https://backstage.arhean.com | Requires Ingress + DNS |
| **Health Check** | http://localhost:7007/healthcheck | Returns JSON status |
| **Metrics** | http://localhost:7007/metrics | Prometheus format |
| **API** | http://localhost:7007/api | Backend API |

---

## 🆘 Emergency Commands

```bash
# Complete restart
kubectl delete deployment backstage -n backstage
make deploy

# Reset database (⚠️ DESTRUCTIVE)
kubectl delete statefulset psql-postgresql -n backstage
kubectl delete pvc data-psql-postgresql-0 -n backstage

# Remove everything and redeploy
kubectl delete namespace backstage
kubectl create namespace backstage
make deploy

# View all resources
kubectl get all -n backstage

# Force delete stuck pod
kubectl delete pod <pod-name> -n backstage --force --grace-period=0
```

---

**📚 For more details, see:**
- [Full Deployment Guide](./DEPLOYMENT_GUIDE.md)
- [Architecture Documentation](../README.md)
- [Makefile](../Makefile)
