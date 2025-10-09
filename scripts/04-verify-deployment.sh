#!/bin/bash
# ============================================================================
# Script: 04-verify-deployment.sh
# Description: Verify Backstage deployment in Kind
# Author: Jaime Henao
# Date: October 3, 2025
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}  Backstage Kind Migration - Phase 4: Verify Deployment${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

FAILED_CHECKS=0

# ============================================================================
# Check 1: Pods Running
# ============================================================================
echo -e "${YELLOW}[Check 1/8]${NC} Verifying pods..."

POD_COUNT=$(kubectl get pods -n backstage -l app=backstage --no-headers 2>/dev/null | wc -l | tr -d ' ')
RUNNING_PODS=$(kubectl get pods -n backstage -l app=backstage --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l | tr -d ' ')

if [ "$RUNNING_PODS" -ge 1 ]; then
    echo -e "${GREEN}✅ Pods running: ${RUNNING_PODS}/${POD_COUNT}${NC}"
else
    echo -e "${RED}❌ No pods running${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
echo ""

# ============================================================================
# Check 2: Service Endpoints
# ============================================================================
echo -e "${YELLOW}[Check 2/8]${NC} Verifying service endpoints..."

ENDPOINTS=$(kubectl get endpoints backstage -n backstage -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)

if [ -n "$ENDPOINTS" ]; then
    echo -e "${GREEN}✅ Service has endpoints: ${ENDPOINTS}${NC}"
else
    echo -e "${RED}❌ No service endpoints${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
echo ""

# ============================================================================
# Check 3: Ingress Configuration
# ============================================================================
echo -e "${YELLOW}[Check 3/8]${NC} Verifying ingress..."

INGRESS_HOST=$(kubectl get ingress backstage -n backstage -o jsonpath='{.spec.rules[0].host}' 2>/dev/null)

if [ "$INGRESS_HOST" == "backstage.kind.local" ]; then
    echo -e "${GREEN}✅ Ingress configured: ${INGRESS_HOST}${NC}"
else
    echo -e "${RED}❌ Ingress not configured correctly${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
echo ""

# ============================================================================
# Check 4: Internal Health Check
# ============================================================================
echo -e "${YELLOW}[Check 4/8]${NC} Testing internal health check..."

POD_NAME=$(kubectl get pod -n backstage -l app=backstage -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "$POD_NAME" ]; then
    HEALTH_CHECK=$(kubectl exec -n backstage "$POD_NAME" -- curl -s -o /dev/null -w "%{http_code}" http://localhost:7007/healthcheck 2>/dev/null || echo "000")

    if [ "$HEALTH_CHECK" == "200" ]; then
        echo -e "${GREEN}✅ Health check passed (200 OK)${NC}"
    else
        echo -e "${RED}❌ Health check failed (HTTP ${HEALTH_CHECK})${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
else
    echo -e "${RED}❌ No pod found to test${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
echo ""

# ============================================================================
# Check 5: PostgreSQL Connection
# ============================================================================
echo -e "${YELLOW}[Check 5/8]${NC} Verifying PostgreSQL connection..."

if [ -n "$POD_NAME" ]; then
    PG_CHECK=$(kubectl exec -n backstage "$POD_NAME" -- nc -zv psql-postgresql.backstage.svc.cluster.local 5432 2>&1 | grep -i "open\|succeeded" || echo "failed")

    if [[ "$PG_CHECK" != "failed" ]]; then
        echo -e "${GREEN}✅ PostgreSQL accessible${NC}"
    else
        echo -e "${RED}❌ PostgreSQL not accessible${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
else
    echo -e "${YELLOW}⚠️  Skipping (no pod available)${NC}"
fi
echo ""

# ============================================================================
# Check 6: External Access via Ingress
# ============================================================================
echo -e "${YELLOW}[Check 6/8]${NC} Testing external access..."

HOSTS_ENTRY=$(grep "backstage.kind.local" /etc/hosts 2>/dev/null || echo "")

if [ -n "$HOSTS_ENTRY" ]; then
    echo -e "${GREEN}✅ /etc/hosts entry exists${NC}"

    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://backstage.kind.local/healthcheck 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" == "200" ]; then
        echo -e "${GREEN}✅ External access working (200 OK)${NC}"
    else
        echo -e "${RED}❌ External access failed (HTTP ${HTTP_CODE})${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
else
    echo -e "${YELLOW}⚠️  /etc/hosts entry missing${NC}"
    echo -e "   Add: ${BLUE}127.0.0.1 backstage.kind.local${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
fi
echo ""

# ============================================================================
# Check 7: Resource Usage
# ============================================================================
echo -e "${YELLOW}[Check 7/8]${NC} Checking resource usage..."

if kubectl top pod -n backstage -l app=backstage &> /dev/null; then
    kubectl top pod -n backstage -l app=backstage
    echo -e "${GREEN}✅ Resource metrics available${NC}"
else
    echo -e "${YELLOW}⚠️  Metrics not available (install metrics-server)${NC}"
fi
echo ""

# ============================================================================
# Check 8: Recent Logs
# ============================================================================
echo -e "${YELLOW}[Check 8/8]${NC} Checking for errors in logs..."

ERROR_COUNT=$(kubectl logs -n backstage -l app=backstage --tail=100 2>/dev/null | grep -i "error\|fatal\|exception" | wc -l | tr -d ' ')

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✅ No errors in recent logs${NC}"
else
    echo -e "${YELLOW}⚠️  Found ${ERROR_COUNT} error(s) in logs${NC}"
    echo -e "${BLUE}Recent errors:${NC}"
    kubectl logs -n backstage -l app=backstage --tail=100 2>/dev/null | grep -i "error\|fatal\|exception" | tail -5
fi
echo ""

# ============================================================================
# Final Summary
# ============================================================================
echo -e "${BLUE}============================================================================${NC}"

if [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${GREEN}  ✅ All Checks Passed - Deployment Successful!${NC}"
    echo -e "${BLUE}============================================================================${NC}"
    echo ""
    echo -e "${GREEN}🎉 Backstage is ready!${NC}"
    echo ""
    echo -e "${BLUE}📍 Access Points:${NC}"
    echo -e "  • UI: ${GREEN}http://backstage.kind.local${NC}"
    echo -e "  • Health: ${GREEN}http://backstage.kind.local/healthcheck${NC}"
    echo ""
    echo -e "${BLUE}📊 Quick Commands:${NC}"
    echo -e "  • View logs: ${YELLOW}kubectl logs -n backstage -l app=backstage -f${NC}"
    echo -e "  • Get pods: ${YELLOW}kubectl get pods -n backstage${NC}"
    echo -e "  • Restart: ${YELLOW}kubectl rollout restart deployment/backstage -n backstage${NC}"
    echo ""
else
    echo -e "${RED}  ❌ ${FAILED_CHECKS} Check(s) Failed${NC}"
    echo -e "${BLUE}============================================================================${NC}"
    echo ""
    echo -e "${YELLOW}🔍 Troubleshooting:${NC}"
    echo ""
    echo -e "${BLUE}1. View pod status:${NC}"
    echo -e "   kubectl get pods -n backstage"
    echo ""
    echo -e "${BLUE}2. View pod logs:${NC}"
    echo -e "   kubectl logs -n backstage -l app=backstage --tail=50"
    echo ""
    echo -e "${BLUE}3. Describe pod:${NC}"
    echo -e "   kubectl describe pod -n backstage -l app=backstage"
    echo ""
    echo -e "${BLUE}4. Check events:${NC}"
    echo -e "   kubectl get events -n backstage --sort-by='.lastTimestamp'"
    echo ""
    echo -e "${BLUE}5. Test internal connectivity:${NC}"
    echo -e "   kubectl exec -n backstage deployment/backstage -- curl http://localhost:7007/healthcheck"
    echo ""
fi

exit $FAILED_CHECKS
