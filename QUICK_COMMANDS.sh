#!/bin/bash
# ============================================================================
# Quick Commands Reference for Backstage Kind Migration
# Copy and paste these commands as needed
# ============================================================================

# Colors for output
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgi='kubectl get ingress'
alias kd='kubectl describe'
alias kl='kubectl logs'

# ============================================================================
# PRE-DEPLOYMENT CHECKS
# ============================================================================

echo "=== Pre-Deployment Checks ==="

# Check cluster
kubectl cluster-info

# Check current backstage
kubectl get all -n backstage

# Check PostgreSQL
kubectl get pods -n backstage psql-postgresql-0

# Check ingress controller
kubectl get pods -n ingress-nginx

# Check /etc/hosts
grep backstage.kind.local /etc/hosts

# ============================================================================
# BACKUP (EXECUTE BEFORE MIGRATION)
# ============================================================================

echo "=== Creating Backups ==="

# Backup namespace
kubectl get all,cm,secret,ingress -n backstage -o yaml > /tmp/backstage-backup-$(date +%Y%m%d-%H%M%S).yaml

# Backup database (if PostgreSQL is accessible)
# kubectl exec -n backstage psql-postgresql-0 -- pg_dump -U postgres backstage > /tmp/backstage-db-$(date +%Y%m%d-%H%M%S).sql

# ============================================================================
# CLEANUP OLD DEPLOYMENT
# ============================================================================

echo "=== Cleanup Old Deployment ==="

# Scale down current deployment (but don't delete)
kubectl scale deployment backstage -n backstage --replicas=0

# Verify pods are gone
kubectl get pods -n backstage -l app=backstage

# Delete old ConfigMaps (optional)
# kubectl delete cm backstage-config backstage-base-config -n backstage 2>/dev/null || true

# Delete old ingresses (optional)
# kubectl delete ingress backstage backstage-enhanced -n backstage 2>/dev/null || true

# ============================================================================
# DEPLOY NEW BACKSTAGE
# ============================================================================

echo "=== Deploying New Backstage ==="

cd /Users/jaime.henao/arheanja/Backstage-solutions/backstage-kind-migration

# Execute deployment script
./scripts/03-deploy-to-kind.sh

# Or manually:
# kubectl apply -f kubernetes/namespace.yaml
# kubectl apply -f kubernetes/rbac.yaml
# kubectl apply -f kubernetes/secrets.yaml
# kubectl apply -f kubernetes/configmap.yaml
# kubectl apply -f kubernetes/service.yaml
# kubectl apply -f kubernetes/deployment.yaml
# kubectl apply -f kubernetes/ingress.yaml

# Wait for rollout
kubectl rollout status deployment/backstage -n backstage --timeout=5m

# ============================================================================
# VERIFICATION
# ============================================================================

echo "=== Verification ==="

# Check pods
kubectl get pods -n backstage

# Check all resources
kubectl get all,ingress -n backstage

# View logs
kubectl logs -n backstage -l app=backstage --tail=50

# Internal health check
kubectl exec -n backstage deployment/backstage -- curl -f http://localhost:7007/healthcheck

# External health check
curl -v http://backstage.kind.local/healthcheck

# Check endpoints
kubectl get endpoints backstage -n backstage

# View recent events
kubectl get events -n backstage --sort-by='.lastTimestamp' | tail -20

# ============================================================================
# MONITORING
# ============================================================================

echo "=== Monitoring Commands ==="

# Follow logs
kubectl logs -n backstage -l app=backstage -f

# Watch pods
watch -n 2 kubectl get pods -n backstage

# Watch events
watch -n 5 'kubectl get events -n backstage --sort-by=.lastTimestamp | tail -10'

# Resource usage (requires metrics-server)
kubectl top pod -n backstage

# Continuous health check
while true; do curl -s http://backstage.kind.local/healthcheck || echo "FAILED"; sleep 5; done

# ============================================================================
# TROUBLESHOOTING
# ============================================================================

echo "=== Troubleshooting ==="

# Describe pod
kubectl describe pod -n backstage -l app=backstage

# View previous logs (if crashed)
kubectl logs -n backstage -l app=backstage --previous

# Check image in Kind
docker exec kind-control-plane crictl images | grep backstage-kind

# Test PostgreSQL connectivity
kubectl exec -n backstage deployment/backstage -- nc -zv psql-postgresql.backstage.svc.cluster.local 5432

# View environment variables
kubectl exec -n backstage deployment/backstage -- env | grep -E "POSTGRES|APP_BASE"

# Exec into pod
kubectl exec -it -n backstage deployment/backstage -- /bin/bash

# Port forward (bypass ingress)
kubectl port-forward -n backstage svc/backstage 7007:80
# Then: curl http://localhost:7007/healthcheck

# View ingress logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller --tail=50

# ============================================================================
# ROLLBACK
# ============================================================================

echo "=== Rollback Commands ==="

# Scale back old deployment (if it exists)
# kubectl scale deployment backstage -n backstage --replicas=1

# Restore from backup
# kubectl apply -f /tmp/backstage-backup-YYYYMMDD-HHMMSS.yaml

# Delete new deployment
# kubectl delete deployment backstage -n backstage

# ============================================================================
# CLEANUP (AFTER SUCCESS)
# ============================================================================

echo "=== Cleanup (after verifying success) ==="

# Delete old replicasets
kubectl delete rs -n backstage $(kubectl get rs -n backstage -o jsonpath='{.items[?(@.spec.replicas==0)].metadata.name}')

# Delete backup files (optional)
# rm /tmp/backstage-backup-*.yaml

# ============================================================================
# QUICK STATUS
# ============================================================================

echo "=== Quick Status ==="

cat << 'EOF'

# One-liner status check
kubectl get pods,svc,ingress -n backstage && \
  curl -s http://backstage.kind.local/healthcheck && \
  echo "✅ Backstage is healthy"

# Full verification
./scripts/04-verify-deployment.sh

EOF
