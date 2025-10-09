# 🏗️ Backstage Architecture - Complete Diagrams

## 📋 Contents

- [Component Architecture](#-component-architecture)
- [Network Flow](#-network-flow)
- [Data Flow](#-data-flow)
- [Deployment Pipeline](#-deployment-pipeline)
- [Security Architecture](#-security-architecture)

---

## 🏛️ Component Architecture

### Complete System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        🌍 Production Environment                             │
│                                                                               │
│  External Users                                                               │
│  👤👤👤 ──▶ https://backstage.arhean.com                                      │
└───────────────────────────────┬─────────────────────────────────────────────┘
                                │
                                │ HTTPS/TLS 1.2+
                                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         🔒 Security Layer                                     │
│                                                                               │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │  🛡️  Ingress Controller (nginx-ingress)                                │  │
│  │                                                                         │  │
│  │  • TLS Termination (Let's Encrypt)                                     │  │
│  │  • Certificate Auto-renewal                                            │  │
│  │  • SSL/TLS v1.2, v1.3 only                                             │  │
│  │  • HTTP → HTTPS redirect                                               │  │
│  │  • Rate limiting                                                        │  │
│  │  • DDoS protection                                                      │  │
│  └───────────────────────────────┬─────────────────────────────────────────┘  │
└─────────────────────────────────┼───────────────────────────────────────────┘
                                  │
                                  │ HTTP (Internal)
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                      ☸️  Kubernetes Cluster (Kind)                           │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │             📦 Namespace: backstage                                  │    │
│  │                                                                       │    │
│  │  ┌──────────────────────────────────────────────────────────────┐  │    │
│  │  │  🔵 Service: backstage                                        │  │    │
│  │  │                                                               │  │    │
│  │  │  Type: ClusterIP                                             │  │    │
│  │  │  Port: 80 → 7007                                             │  │    │
│  │  │  Session Affinity: ClientIP (3h timeout)                     │  │    │
│  │  │  Selector: app=backstage                                     │  │    │
│  │  └────────────────────────┬─────────────────────────────────────┘  │    │
│  │                           │                                         │    │
│  │                           │ Load Balancing                          │    │
│  │                           ▼                                         │    │
│  │  ┌──────────────────────────────────────────────────────────────┐  │    │
│  │  │  📊 Deployment: backstage                                     │  │    │
│  │  │                                                               │  │    │
│  │  │  Strategy: RollingUpdate                                     │  │    │
│  │  │  ├─ maxUnavailable: 1                                        │  │    │
│  │  │  └─ maxSurge: 1                                              │  │    │
│  │  │                                                               │  │    │
│  │  │  Current Replicas: 1                                         │  │    │
│  │  │  Desired Replicas: 1                                         │  │    │
│  │  │                                                               │  │    │
│  │  │  ┌─────────────────────────────────────────────────────┐    │  │    │
│  │  │  │   Pod: backstage-76b7ff7c68-gtf48                    │    │  │    │
│  │  │  │                                                       │    │  │    │
│  │  │  │  Labels:                                              │    │  │    │
│  │  │  │  • app: backstage                                     │    │  │    │
│  │  │  │  • component: backend                                 │    │  │    │
│  │  │  │  • pod-template-hash: 76b7ff7c68                      │    │  │    │
│  │  │  │                                                       │    │  │    │
│  │  │  │  Annotations:                                         │    │  │    │
│  │  │  │  • prometheus.io/scrape: "true"                       │    │  │    │
│  │  │  │  • prometheus.io/port: "7007"                         │    │  │    │
│  │  │  │  • prometheus.io/path: "/metrics"                     │    │  │    │
│  │  │  │                                                       │    │  │    │
│  │  │  │  ┌──────────────────────────────────────────────┐   │    │  │    │
│  │  │  │  │  🔧 Init Container: wait-for-postgres        │   │    │  │    │
│  │  │  │  │                                              │   │    │  │    │
│  │  │  │  │  Image: busybox:1.36                         │   │    │  │    │
│  │  │  │  │  Command:                                    │   │    │  │    │
│  │  │  │  │    while ! nc -z postgres 5432; do           │   │    │  │    │
│  │  │  │  │      sleep 2                                 │   │    │  │    │
│  │  │  │  │    done                                      │   │    │  │    │
│  │  │  │  │                                              │   │    │  │    │
│  │  │  │  │  Resources:                                  │   │    │  │    │
│  │  │  │  │    requests: { cpu: 50m, memory: 64Mi }     │   │    │  │    │
│  │  │  │  │    limits: { cpu: 100m, memory: 128Mi }     │   │    │  │    │
│  │  │  │  └──────────────────────────────────────────────┘   │    │  │    │
│  │  │  │                                                       │    │  │    │
│  │  │  │  ┌──────────────────────────────────────────────┐   │    │  │    │
│  │  │  │  │  🎭 Main Container: backstage                │   │    │  │    │
│  │  │  │  │                                              │   │    │  │    │
│  │  │  │  │  Image: jaimehenao8126/backstage-           │   │    │  │    │
│  │  │  │  │         production:v7                        │   │    │  │    │
│  │  │  │  │  Pull Policy: Always                         │   │    │  │    │
│  │  │  │  │                                              │   │    │  │    │
│  │  │  │  │  Port: 7007/TCP (http)                       │   │    │  │    │
│  │  │  │  │                                              │   │    │  │    │
│  │  │  │  │  ┌──────────────────────────────────────┐   │   │    │  │    │
│  │  │  │  │  │  📦 Application Stack                │   │   │    │  │    │
│  │  │  │  │  │                                      │   │   │    │  │    │
│  │  │  │  │  │  Node.js 20 LTS                      │   │   │    │  │    │
│  │  │  │  │  │  ├─ Express.js (Backend API)         │   │   │    │  │    │
│  │  │  │  │  │  ├─ React 18 (Frontend SPA)          │   │   │    │  │    │
│  │  │  │  │  │  ├─ TypeScript 5.8                   │   │   │    │  │    │
│  │  │  │  │  │  └─ Backstage Plugins:               │   │   │    │  │    │
│  │  │  │  │  │     • @backstage/plugin-catalog      │   │   │    │  │    │
│  │  │  │  │  │     • @backstage/plugin-kubernetes   │   │   │    │  │    │
│  │  │  │  │  │     • @backstage/plugin-techdocs     │   │   │    │  │    │
│  │  │  │  │  │     • @roadiehq/plugin-argo-cd       │   │   │    │  │    │
│  │  │  │  │  └──────────────────────────────────────┘   │   │    │  │    │
│  │  │  │  │                                              │   │    │  │    │
│  │  │  │  │  Environment Variables:                      │   │    │  │    │
│  │  │  │  │  • NODE_ENV=production                       │   │    │  │    │
│  │  │  │  │  • NODE_OPTIONS=--max-old-space-size=1024    │   │    │  │    │
│  │  │  │  │  • From ConfigMap: backstage-env-config      │   │    │  │    │
│  │  │  │  │  • From Secret: backstage-secrets            │   │    │  │    │
│  │  │  │  │                                              │   │    │  │    │
│  │  │  │  │  Resources:                                  │   │    │  │    │
│  │  │  │  │    requests:                                 │   │    │  │    │
│  │  │  │  │      cpu: 250m (0.25 cores)                  │   │    │  │    │
│  │  │  │  │      memory: 512Mi                           │   │    │  │    │
│  │  │  │  │    limits:                                   │   │    │  │    │
│  │  │  │  │      cpu: 1000m (1 core)                     │   │    │  │    │
│  │  │  │  │      memory: 2Gi                             │   │    │  │    │
│  │  │  │  │                                              │   │    │  │    │
│  │  │  │  │  Volume Mounts:                              │   │    │  │    │
│  │  │  │  │  • /tmp (emptyDir, 1Gi)                      │   │    │  │    │
│  │  │  │  │  • /app/tmp (emptyDir, 1Gi)                  │   │    │  │    │
│  │  │  │  │                                              │   │    │  │    │
│  │  │  │  │  Health Checks:                              │   │    │  │    │
│  │  │  │  │  ✅ Startup:  /healthcheck (max 2min)        │   │    │  │    │
│  │  │  │  │  ✅ Liveness: /healthcheck (every 30s)       │   │    │  │    │
│  │  │  │  │  ✅ Readiness: /healthcheck (every 10s)      │   │    │  │    │
│  │  │  │  │                                              │   │    │  │    │
│  │  │  │  │  Security Context:                           │   │    │  │    │
│  │  │  │  │  • runAsNonRoot: true                        │   │    │  │    │
│  │  │  │  │  • runAsUser: 1000                           │   │    │  │    │
│  │  │  │  │  • allowPrivilegeEscalation: false           │   │    │  │    │
│  │  │  │  │  • capabilities: drop ALL                    │   │    │  │    │
│  │  │  │  └──────────────────────────────────────────────┘   │    │  │    │
│  │  │  └───────────────────────────────────────────────────────┘    │  │    │
│  │  └──────────────────────────────────────────────────────────────┘  │    │
│  │                                                                      │    │
│  │  ┌──────────────────────────────────────────────────────────────┐  │    │
│  │  │  🗄️  StatefulSet: psql-postgresql                            │  │    │
│  │  │                                                               │  │    │
│  │  │  Replicas: 1                                                 │  │    │
│  │  │  Pod Management Policy: OrderedReady                         │  │    │
│  │  │                                                               │  │    │
│  │  │  ┌─────────────────────────────────────────────────────┐    │  │    │
│  │  │  │   Pod: psql-postgresql-0                            │    │  │    │
│  │  │  │                                                       │    │  │    │
│  │  │  │  ┌────────────────────────────────────────────┐     │    │  │    │
│  │  │  │  │  🐘 PostgreSQL 14                          │     │    │  │    │
│  │  │  │  │                                            │     │    │  │    │
│  │  │  │  │  Port: 5432/TCP                            │     │    │  │    │
│  │  │  │  │  Database: backstage_plugin_catalog        │     │    │  │    │
│  │  │  │  │                                            │     │    │  │    │
│  │  │  │  │  Volume:                                   │     │    │  │    │
│  │  │  │  │  • PVC: data-psql-postgresql-0             │     │    │  │    │
│  │  │  │  │  • Size: 8Gi                               │     │    │  │    │
│  │  │  │  │  • StorageClass: standard (or hostpath)    │     │    │  │    │
│  │  │  │  │  • Mount: /var/lib/postgresql/data         │     │    │  │    │
│  │  │  │  │                                            │     │    │  │    │
│  │  │  │  │  Connections:                              │     │    │  │    │
│  │  │  │  │  • Max connections: 100                    │     │    │  │    │
│  │  │  │  │  • Shared buffers: 256MB                   │     │    │  │    │
│  │  │  │  └────────────────────────────────────────────┘     │    │  │    │
│  │  │  └─────────────────────────────────────────────────────┘    │  │    │
│  │  └──────────────────────────────────────────────────────────────┘  │    │
│  │                                                                      │    │
│  │  ┌──────────────────────────────────────────────────────────────┐  │    │
│  │  │  📋 ConfigMap: backstage-env-config                           │  │    │
│  │  │                                                               │  │    │
│  │  │  Data (12 entries):                                           │  │    │
│  │  │  • NODE_ENV: production                                       │  │    │
│  │  │  • POSTGRES_HOST: psql-postgresql.backstage.svc.cluster.local│  │    │
│  │  │  • POSTGRES_PORT: 5432                                        │  │    │
│  │  │  • POSTGRES_DB: backstage_plugin_catalog                      │  │    │
│  │  │  • BACKEND_URL: https://backstage.arhean.com                  │  │    │
│  │  │  • ... (more environment variables)                           │  │    │
│  │  └──────────────────────────────────────────────────────────────┘  │    │
│  │                                                                      │    │
│  │  ┌──────────────────────────────────────────────────────────────┐  │    │
│  │  │  🔐 Secret: backstage-secrets                                 │  │    │
│  │  │                                                               │  │    │
│  │  │  Data (5 entries, base64 encoded):                            │  │    │
│  │  │  • POSTGRES_USER: *****                                       │  │    │
│  │  │  • POSTGRES_PASSWORD: *****                                   │  │    │
│  │  │  • GITHUB_TOKEN: ghp_*****                                    │  │    │
│  │  │  • GITHUB_CLIENT_ID: *****                                    │  │    │
│  │  │  • GITHUB_CLIENT_SECRET: *****                                │  │    │
│  │  └──────────────────────────────────────────────────────────────┘  │    │
│  │                                                                      │    │
│  │  ┌──────────────────────────────────────────────────────────────┐  │    │
│  │  │  🔑 ServiceAccount: backstage                                 │  │    │
│  │  │  ClusterRole: backstage-backend                               │  │    │
│  │  │  ClusterRoleBinding: backstage-backend                        │  │    │
│  │  │                                                               │  │    │
│  │  │  Permissions:                                                 │  │    │
│  │  │  • apiGroups: ["*"]                                           │  │    │
│  │  │  • resources: ["*"]                                           │  │    │
│  │  │  • verbs: ["get", "list", "watch"]                            │  │    │
│  │  └──────────────────────────────────────────────────────────────┘  │    │
│  └──────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🌐 Network Flow

### Request Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Complete Request Flow                         │
└─────────────────────────────────────────────────────────────────┘

Step 1: External Request
┌──────────┐
│  👤 User  │  GET https://backstage.arhean.com/catalog
└─────┬────┘
      │
      │ ① DNS Resolution
      ▼
   DNS Server
      │
      │ ② Resolves to: 192.168.1.100
      ▼
┌────────────────┐
│  Load Balancer │  (or Ingress IP)
└───────┬────────┘
        │
        │ ③ HTTPS/443 (TLS encrypted)
        ▼
┌─────────────────────────────────────────────────────────────────┐
│  Ingress Controller (nginx)                                      │
│                                                                   │
│  ④ TLS Termination:                                              │
│     • Validates client certificate (if mTLS)                     │
│     • Decrypts HTTPS → HTTP                                      │
│     • Checks Host header: backstage.arhean.com                   │
│     • Applies rate limiting                                      │
│     • Logs request                                               │
│                                                                   │
│  ⑤ Route Selection:                                              │
│     • Path: /catalog                                             │
│     • Backend: backstage-service:80                              │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ ⑥ HTTP/80 (Internal network)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  Service: backstage (ClusterIP)                                  │
│                                                                   │
│  ⑦ Load Balancing:                                               │
│     • Type: ClusterIP (10.96.123.45:80)                          │
│     • Session Affinity: ClientIP                                 │
│     • Selects Pod based on IP hash                               │
│     • Target: backstage-76b7ff7c68-gtf48:7007                    │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ ⑧ HTTP/7007 (Pod network)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  Pod: backstage-76b7ff7c68-gtf48                                 │
│                                                                   │
│  ⑨ Container receives request:                                   │
│     • Port: 7007                                                 │
│     • Process: Node.js (PID 1)                                   │
│     • Handler: Express.js router                                 │
│                                                                   │
│  ⑩ Application Processing:                                       │
│                                                                   │
│     ┌──────────────────┐                                         │
│     │  Express Router  │                                         │
│     └────────┬─────────┘                                         │
│              │                                                    │
│              ├─▶ Auth Middleware (check JWT/session)             │
│              ├─▶ CORS Middleware                                 │
│              ├─▶ Logging Middleware                              │
│              │                                                    │
│              ▼                                                    │
│     ┌──────────────────┐                                         │
│     │ Catalog Plugin   │                                         │
│     └────────┬─────────┘                                         │
│              │                                                    │
│              │ ⑪ Database Query                                  │
│              ▼                                                    │
│     ┌──────────────────────────────────────┐                     │
│     │  PostgreSQL Client                   │                     │
│     │  SELECT * FROM catalog_entities      │                     │
│     │  WHERE kind = 'Component'            │                     │
│     └────────┬─────────────────────────────┘                     │
└──────────────┼─────────────────────────────────────────────────┘
               │
               │ ⑫ PostgreSQL Protocol (port 5432)
               ▼
┌─────────────────────────────────────────────────────────────────┐
│  Pod: psql-postgresql-0                                          │
│                                                                   │
│  ⑬ Database Query Execution:                                     │
│     • Receives query                                             │
│     • Parses SQL                                                 │
│     • Executes query plan                                        │
│     • Fetches from disk/cache                                    │
│     • Returns result set                                         │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ ⑭ Result (rows)
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  Backstage Pod - Response Processing                             │
│                                                                   │
│  ⑮ Transform Data:                                               │
│     • Convert DB rows → JSON                                     │
│     • Apply business logic                                       │
│     • Add metadata                                               │
│     • Format response                                            │
│                                                                   │
│  ⑯ Send Response:                                                │
│     HTTP/1.1 200 OK                                              │
│     Content-Type: application/json                               │
│     {                                                            │
│       "items": [...],                                            │
│       "totalCount": 42                                           │
│     }                                                            │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ ⑰ Response flows back
                            ▼
       Service ─▶ Ingress ─▶ Load Balancer ─▶ Internet ─▶ User

Total Latency Breakdown:
┌────────────────────────────────────────┐
│  DNS Resolution:          ~10-50ms     │
│  TLS Handshake:           ~50-100ms    │
│  Ingress Routing:         ~5-10ms      │
│  Service Load Balance:    ~1-5ms       │
│  App Processing:          ~50-200ms    │
│  Database Query:          ~10-100ms    │
│  Response Assembly:       ~10-50ms     │
│  ──────────────────────────────────    │
│  Total (typical):         ~150-500ms   │
└────────────────────────────────────────┘
```

### Network Policies (if enabled)

```
┌──────────────────────────────────────────────────────────────┐
│              Network Segmentation                             │
└──────────────────────────────────────────────────────────────┘

┌─────────────────┐       ┌─────────────────┐
│   Ingress       │       │  Other          │
│   Controller    │       │  Namespaces     │
└────────┬────────┘       └────────┬────────┘
         │                         │
         │ ✅ Allowed              │ ❌ Denied
         ▼                         ▼
    ┌────────────────────────────────────┐
    │   backstage namespace              │
    │                                    │
    │  ┌──────────┐     ┌──────────┐   │
    │  │Backstage │────▶│PostgreSQL│   │
    │  │  Pod     │     │   Pod    │   │
    │  └──────────┘     └──────────┘   │
    │       │                │          │
    │       │ ✅ Port 5432   │          │
    │       └────────────────┘          │
    │                                    │
    │  Internet egress: ✅ Allowed      │
    │  (for GitHub API, etc.)           │
    └────────────────────────────────────┘
```

---

## 📊 Data Flow

### Application Data Flow

```
┌────────────────────────────────────────────────────────────────┐
│               Backstage Data Flow Architecture                  │
└────────────────────────────────────────────────────────────────┘

External Sources                Backstage                  Storage
─────────────────              ─────────                  ─────────

┌──────────────┐               ┌──────────────────┐
│   GitHub     │──────────────▶│  Catalog         │
│   API        │               │  Processor       │
└──────────────┘               └────────┬─────────┘
                                        │
┌──────────────┐                        │ ① Discover
│   GitLab     │──────────────▶         │    Repositories
│   API        │                        │
└──────────────┘                        │
                                        ▼
┌──────────────┐               ┌──────────────────┐
│  Kubernetes  │──────────────▶│  Entity          │
│  API         │               │  Providers       │
└──────────────┘               └────────┬─────────┘
                                        │
                                        │ ② Parse
                                        │    catalog-info.yaml
                                        │
                                        ▼
                               ┌──────────────────┐      ┌─────────────┐
                               │  Entity          │─────▶│ PostgreSQL  │
                               │  Transformer     │      │             │
                               └────────┬─────────┘      │  Tables:    │
                                        │                │  • entities │
                                        │                │  • relations│
                                        │ ③ Transform    │  • metadata │
                                        │    & Validate  └─────────────┘
                                        │
                                        ▼
                               ┌──────────────────┐
                               │  Database        │
                               │  Writer          │
                               └────────┬─────────┘
                                        │
                                        │ ④ Store
                                        │    Entities
                                        │
                                        ▼
                               ┌──────────────────────────────────────┐
                               │  PostgreSQL Database                  │
                               │                                      │
                               │  backstage_plugin_catalog            │
                               │  ├─ entities (10K+ rows)             │
                               │  │   • uid, name, kind, namespace    │
                               │  │   • metadata (JSON)               │
                               │  │   • spec (JSON)                   │
                               │  │                                   │
                               │  ├─ relations (50K+ rows)            │
                               │  │   • source_entity_ref             │
                               │  │   • target_entity_ref             │
                               │  │   • type (ownedBy, partOf, etc.)  │
                               │  │                                   │
                               │  └─ refresh_state                    │
                               │      • entity_id                     │
                               │      • last_discovery                │
                               │      • next_update                   │
                               └──────────────────────────────────────┘
                                        ▲
                                        │
                                        │ ⑤ Read
                                        │    Queries
                                        │
                               ┌────────┴─────────┐
                               │  Catalog API     │
                               │  Endpoints       │
                               └────────┬─────────┘
                                        │
                                        │ ⑥ Serve
                                        │    to UI
                                        ▼
                               ┌──────────────────┐
                               │  React Frontend  │
                               │                  │
                               │  Components:     │
                               │  • EntityPage    │
                               │  • CatalogTable  │
                               │  • EntityGraph   │
                               └──────────────────┘
                                        │
                                        │ ⑦ Render
                                        │    to User
                                        ▼
                                  ┌─────────┐
                                  │ 👤 User │
                                  └─────────┘
```

### Plugin Data Flow Example

```
┌─────────────────────────────────────────────────────────────────┐
│          Kubernetes Plugin - Pod Information Flow                │
└─────────────────────────────────────────────────────────────────┘

User Action                  Frontend              Backend            K8s
───────────                 ─────────             ────────           ─────

👤 Clicks                    ┌─────────┐
"View Pods" ──────────▶│ React    │
                             │ Component│
                             └─────┬────┘
                                   │
                                   │ ① API Call
                                   │ GET /api/kubernetes/pods
                                   ▼
                            ┌──────────────┐
                            │  Backend API │
                            │  Router      │
                            └──────┬───────┘
                                   │
                                   │ ② Auth Check
                                   │ (JWT validation)
                                   ▼
                            ┌──────────────┐
                            │  Kubernetes  │
                            │  Plugin      │
                            └──────┬───────┘
                                   │
                                   │ ③ Identify
                                   │    Cluster
                                   ▼
                            ┌──────────────┐
                            │  Cluster     │
                            │  Supplier    │
                            └──────┬───────┘
                                   │
                                   │ ④ Get
                                   │    Credentials
                                   ▼
                            ┌──────────────────┐
                            │  ServiceAccount  │
                            │  Token           │
                            └──────┬───────────┘
                                   │
                                   │ ⑤ API Request
                                   │ GET /api/v1/pods
                                   ▼
                            ┌────────────────────────┐
                            │  Kubernetes API Server │
                            │  (in-cluster)          │
                            └──────┬─────────────────┘
                                   │
                                   │ ⑥ RBAC Check
                                   │ (can list pods?)
                                   ▼
                            ┌────────────────┐
                            │  Pod List      │
                            │  Response      │
                            └──────┬─────────┘
                                   │
                                   │ ⑦ Transform
                                   │    to JSON
                                   ▼
                            ┌────────────────┐
                            │  Backstage     │
                            │  Plugin        │
                            └──────┬─────────┘
                                   │
                                   │ ⑧ Return
                                   │    Response
                                   ▼
                            ┌────────────────┐
                            │  React         │
                            │  Component     │
                            └──────┬─────────┘
                                   │
                                   │ ⑨ Render
                                   │    Table
                                   ▼
                            ┌────────────────┐
                            │  Pod Table     │
                            │  ┌───────────┐ │
                            │  │Name Status│ │
                            │  │app  Ready │ │
                            │  │db   Ready │ │
                            │  └───────────┘ │
                            └────────────────┘
```

---

**Continue to Security Architecture in next section...**
