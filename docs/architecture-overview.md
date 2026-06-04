# Log Aggregator - Project Architecture Overview

This document explains the project architecture and the relationships between the different components (pods/services) in the observability platform.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture Diagram](#architecture-diagram)
3. [Component Details](#component-details)
4. [Data Flow](#data-flow)
5. [Deployment Modes](#deployment-modes)
6. [Kubernetes Resources](#kubernetes-resources)
7. [Metrics & Observability](#metrics--observability)

---

## Project Overview

This project is a **complete observability platform** that provides:

- **Log Aggregation**: Centralized log collection and storage using Loki
- **Metrics Collection**: Infrastructure and application metrics using Prometheus
- **Visualization**: Pre-configured Grafana dashboards for monitoring
- **Sample Application**: A Go-based log generator that demonstrates observability patterns

### Key Features

- 📊 **Multi-source log collection** (Promtail/Alloy)
- 📈 **Infrastructure metrics** (Node Exporter, kube-state-metrics)
- 🔍 **Application metrics** (Go Prometheus client)
- 📉 **Pre-built dashboards** (Application, Infrastructure, Logs)
- 🐳 **Dual deployment** (Docker Compose & Kubernetes)

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              OBSERVABILITY PLATFORM                              │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                        APPLICATION LAYER                                 │    │
│  │                                                                           │    │
│  │   ┌─────────────────────┐                                                │    │
│  │   │   Log Generator      │                                                │    │
│  │   │   (Go Application)   │                                                │    │
│  │   │                       │                                                │    │
│  │   │  • Generates logs     │──────┐                                        │    │
│  │   │  • /metrics endpoint  │      │                                        │    │
│  │   │  • /health endpoint   │      │                                        │    │
│  │   │  • Prometheus metrics │      │                                        │    │
│  │   └─────────────────────┘      │                                        │    │
│  │            │                    │                                        │    │
│  │            │ stdout             │ HTTP :8080                             │    │
│  │            ▼                    ▼                                        │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
│                                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                        COLLECTION LAYER                                  │    │
│  │                                                                           │    │
│  │   ┌─────────────────────┐    ┌─────────────────────┐                     │    │
│  │   │    Promtail         │    │    Prometheus        │                     │    │
│  │   │    (DaemonSet)      │    │    (StatefulSet)     │                     │    │
│  │   │                     │    │                      │                     │    │
│  │   │  • Reads container  │    │  • Scrapes metrics   │                     │    │
│  │   │    logs from nodes  │    │  • Stores in TSDB    │                     │    │
│  │   │  • Parses JSON/cri  │    │  • PromQL queries    │                     │    │
│  │   │  • Pushes to Loki   │    │                      │                     │    │
│  │   └─────────────────────┘    └─────────────────────┘                     │    │
│  │            │                            ▲                                │    │
│  │            │                            │                                 │    │
│  │            │                ┌───────────┴───────────┐                    │    │
│  │            │                │                       │                    │    │
│  │            │                ▼                       ▼                    │    │
│  │            │    ┌───────────────────┐  ┌───────────────────┐            │    │
│  │            │    │  Node Exporter    │  │ kube-state-metrics│            │    │
│  │            │    │  (DaemonSet)       │  │ (Deployment)       │            │    │
│  │            │    │                    │  │                     │            │    │
│  │            │    │  • CPU metrics     │  │  • Pod status      │            │    │
│  │            │    │  • Memory usage    │  │  • Deployment status│            │    │
│  │            │    │  • Disk I/O        │  │  • Node info       │            │    │
│  │            │    │  • Network stats   │  │  • Resource quotas │            │    │
│  │            │    └───────────────────┘  └───────────────────┘            │    │
│  │            │                │                       │                    │    │
│  └────────────┼────────────────┼───────────────────────┼────────────────────┘    │
│               │                │                       │                         │
│               ▼                │                       │                         │
│  ┌─────────────────────────────┼───────────────────────┼─────────────────────┐   │
│  │       STORAGE LAYER         │                       │                     │   │
│  │                             │                       │                     │   │
│  │   ┌─────────────────────┐   │                       │                     │   │
│  │   │       Loki          │   │                       │                     │   │
│  │   │   (StatefulSet)     │   │                       │                     │   │
│  │   │                     │   │                       │                     │   │
│  │   │  • Log storage      │◄──┘                       │                     │   │
│  │   │  • LogQL queries    │                           │                     │   │
│  │   │  • Index & chunks   │                           │                     │   │
│  │   └─────────────────────┘                           │                     │   │
│  │                                                     │                     │   │
│  │   ┌─────────────────────────────────────────────────┘                     │   │
│  │   │   Prometheus TSDB                                                       │   │
│  │   │   (Time Series Database)                                                │   │
│  │   │                                                                          │   │
│  │   │   • Metrics storage                                                      │   │
│  │   │   • 15-day retention                                                     │   │
│  │   │   • Compression & indexing                                               │   │
│  │   └──────────────────────────────────────────────────────────────────────────┘   │
│  │                                                                                  │
│  └──────────────────────────────────────────────────────────────────────────────────┘
│                                                                                  │
│  ┌──────────────────────────────────────────────────────────────────────────────┐  │
│  │                        VISUALIZATION LAYER                                    │  │
│  │                                                                                │  │
│  │   ┌───────────────────────────────────────────────────────────────────────┐   │  │
│  │   │                          Grafana                                       │   │  │
│  │   │                        (Deployment)                                    │   │  │
│  │   │                                                                         │   │  │
│  │   │   ┌─────────────────┐      ┌─────────────────┐      ┌───────────────┐ │   │  │
│  │   │   │  Application    │      │ Infrastructure  │      │     Logs      │ │   │  │
│  │   │   │  Dashboard      │      │ Dashboard        │      │   Dashboard   │ │   │  │
│  │   │   │                 │      │                  │      │               │ │   │  │
│  │   │   │ • Log rates     │      │ • CPU usage      │      │ • Log viewer  │ │   │  │
│  │   │   │ • Error counts  │      │ • Memory usage   │      │ • Error count │ │   │  │
│  │   │   │ • Latency p50/95│      │ • Disk I/O       │      │ • Log rate    │ │   │  │
│  │   │   │ • Connections   │      │ • Network        │      │ • Filters     │ │   │  │
│  │   │   └─────────────────┘      └─────────────────┘      └───────────────┘ │   │  │
│  │   │                                                                         │   │  │
│  │   │   Data Sources:                                                          │   │  │
│  │   │   ├── Loki (LogQL) ─────────────────────────────────────► Loki         │   │  │
│  │   │   └── Prometheus (PromQL) ──────────────────────────────► Prometheus   │   │  │
│  │   └───────────────────────────────────────────────────────────────────────┘   │  │
│  │                                                                                │  │
│  └────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## Component Details

### 1. Log Generator (Go Application)

**File:** [`app/main.go`](app/main.go)

**Purpose:** Sample application that generates structured logs and exposes Prometheus metrics.

**Key Features:**
- Generates random log messages at different levels (INFO, WARN, ERROR, DEBUG)
- Exposes `/metrics` endpoint for Prometheus scraping
- Exposes `/health` endpoint for health checks
- Tracks metrics:
  - `log_messages_total` - Counter of logs by level
  - `log_latency_seconds` - Histogram of log processing time
  - `active_connections` - Gauge of simulated connections
  - `http_requests_total` - Counter of HTTP requests
  - `http_request_duration_seconds` - Histogram of request duration

**Kubernetes Resources:**
- Deployment: [`k8s/04-log-generator.yaml`](k8s/04-log-generator.yaml)
- Service: `log-generator:8080`

**Docker Compose:**
- Service: `log-generator`
- Port: `8080:8080`

---

### 2. Promtail (Log Collector)

**File:** [`k8s/02-promtail.yaml`](k8s/02-promtail.yaml), [`config/promtail.yaml`](config/promtail.yaml)

**Purpose:** Collects logs from Kubernetes pods and sends them to Loki.

**Key Features:**
- Runs as DaemonSet (one pod per node)
- Discovers pods via Kubernetes API
- Parses CRI/JSON log format
- Extracts labels (app, namespace, pod, container, level)
- Pushes logs to Loki via HTTP API

**Configuration:**
```yaml
clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: kubernetes-pods
    kubernetes_sd_configs:
      - role: pod
    pipeline_stages:
      - cri: {}          # Parse CRI log format
      - json:            # Extract JSON fields
          expressions:
            level: level
            msg: msg
      - labels:
          level: level
```

**Data Flow:**
```
Pod Logs → Promtail (reads /var/log/pods/*) → Loki (HTTP push)
```

---

### 3. Loki (Log Storage)

**File:** [`k8s/01-loki.yaml`](k8s/01-loki.yaml), [`config/loki.yaml`](config/loki.yaml)

**Purpose:** Stores and indexes log data for querying.

**Key Features:**
- Stores logs in chunks on filesystem
- Indexes labels for fast queries
- Provides LogQL query interface
- Supports retention policies

**Configuration:**
```yaml
schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

limits_config:
  ingestion_rate_mb: 20
  ingestion_burst_size_mb: 30
```

**Storage:**
- Persistent Volume: `loki-data` (1Gi)
- Path: `/loki/chunks`, `/loki/index`

---

### 4. Prometheus (Metrics Storage)

**File:** [`k8s/05-prometheus.yaml`](k8s/05-prometheus.yaml), [`config/prometheus.yaml`](config/prometheus.yaml)

**Purpose:** Scrapes, stores, and queries time-series metrics.

**Key Features:**
- Pull-based metrics collection
- Time Series Database (TSDB)
- PromQL query language
- Service discovery (Kubernetes)
- 15-day retention

**Scrape Targets:**

| Target | Role | Metrics |
|--------|------|---------|
| `prometheus` | Self-monitoring | Internal metrics |
| `node-exporter` | Host metrics | CPU, memory, disk, network |
| `kube-state-metrics` | K8s objects | Pods, deployments, nodes |
| `log-generator` | Application | Custom Go metrics |

**Configuration:**
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    kubernetes_sd_configs:
      - role: endpoints
    relabel_configs:
      - source_labels: [__meta_kubernetes_service_label_app]
        action: keep
        regex: node-exporter

  - job_name: 'log-generator'
    kubernetes_sd_configs:
      - role: pod
        namespaces:
          names: [logging]
```

---

### 5. Node Exporter (Host Metrics)

**File:** [`k8s/06-node-exporter.yaml`](k8s/06-node-exporter.yaml)

**Purpose:** Exposes host-level metrics from Kubernetes nodes.

**Key Features:**
- Runs as DaemonSet (one per node)
- Mounts host filesystems (read-only)
- Exposes metrics on port 9100

**Metrics Exposed:**
- `node_cpu_seconds_total` - CPU time by mode
- `node_memory_MemTotal_bytes` - Total memory
- `node_memory_MemAvailable_bytes` - Available memory
- `node_filesystem_*` - Disk usage
- `node_network_*` - Network I/O

**Volume Mounts:**
```yaml
volumes:
  - name: proc
    hostPath:
      path: /proc
  - name: sys
    hostPath:
      path: /sys
  - name: root
    hostPath:
      path: /
```

---

### 6. kube-state-metrics (Kubernetes Metrics)

**File:** [`k8s/07-kube-state-metrics.yaml`](k8s/07-kube-state-metrics.yaml)

**Purpose:** Exposes metrics about Kubernetes objects (pods, deployments, etc.).

**Key Features:**
- Watches Kubernetes API
- Exposes metrics on port 8080
- Provides telemetry on port 8081

**Metrics Exposed:**
- `kube_pod_info` - Pod metadata
- `kube_pod_status_phase` - Pod status (Running, Pending, etc.)
- `kube_deployment_status_replicas` - Deployment replicas
- `kube_node_info` - Node information
- `kube_persistentvolumeclaim_status` - PVC status

**RBAC Permissions:**
```yaml
rules:
  - apiGroups: [""]
    resources:
      - pods
      - services
      - nodes
      - configmaps
    verbs: ["list", "watch"]
  - apiGroups: ["apps"]
    resources:
      - deployments
      - daemonsets
      - replicasets
    verbs: ["list", "watch"]
```

---

### 7. Grafana (Visualization)

**File:** [`k8s/03-grafana.yaml`](k8s/03-grafana.yaml), [`config/grafana-datasources.yaml`](config/grafana-datasources.yaml)

**Purpose:** Web UI for visualizing logs and metrics.

**Key Features:**
- Pre-configured datasources (Loki, Prometheus)
- Auto-provisioned dashboards
- Anonymous admin access (dev mode)

**Data Sources:**
```yaml
datasources:
  - name: Loki
    type: loki
    url: http://loki:3100
    isDefault: true

  - name: Prometheus
    type: prometheus
    url: http://prometheus:9090
```

**Dashboards:**
| Dashboard | File | Purpose |
|-----------|------|---------|
| Application Metrics | [`application-metrics.json`](config/dashboards/application-metrics.json) | Go app metrics |
| Infrastructure Metrics | [`infrastructure-metrics.json`](config/dashboards/infrastructure-metrics.json) | Node/K8s metrics |
| Logs Overview | [`logs-overview.json`](config/dashboards/logs-overview.json) | Log exploration |

---

## Data Flow

### Log Flow

```
┌─────────────────┐
│ Log Generator   │
│ (Go App)        │
│                 │
│ stdout: logs    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Kubernetes      │
│ Container       │
│ Runtime         │
│ /var/log/pods/* │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Promtail        │
│ (DaemonSet)     │
│                 │
│ - Read logs     │
│ - Parse JSON    │
│ - Add labels    │
└────────┬────────┘
         │
         │ HTTP POST
         │ /loki/api/v1/push
         ▼
┌─────────────────┐
│ Loki            │
│ (StatefulSet)   │
│                 │
│ - Store chunks  │
│ - Index labels  │
└────────┬────────┘
         │
         │ LogQL Query
         ▼
┌─────────────────┐
│ Grafana         │
│                 │
│ - Dashboards    │
│ - Explore       │
└─────────────────┘
```

### Metrics Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     METRICS SOURCES                          │
├─────────────────┬─────────────────┬─────────────────────────┤
│ Log Generator   │ Node Exporter   │ kube-state-metrics       │
│ :8080/metrics   │ :9100/metrics   │ :8080/metrics            │
│                 │                 │                          │
│ - log_messages  │ - node_cpu      │ - kube_pod_info          │
│ - log_latency   │ - node_memory   │ - kube_deployment_*      │
│ - connections   │ - node_filesys  │ - kube_node_info         │
└────────┬────────┴────────┬────────┴────────┬────────────────┘
         │                 │                  │
         │                 │                  │
         └─────────────────┼──────────────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │ Prometheus      │
                  │ (StatefulSet)   │
                  │                 │
                  │ - Scrape /metrics│
                  │ - Store in TSDB │
                  │ - 15d retention  │
                  └────────┬────────┘
                           │
                           │ PromQL Query
                           ▼
                  ┌─────────────────┐
                  │ Grafana         │
                  │                 │
                  │ - Dashboards    │
                  │ - Alerts        │
                  └─────────────────┘
```

---

## Deployment Modes

### Docker Compose (Development)

**File:** [`docker-compose.yml`](docker-compose.yml)

```bash
# Start all services
docker-compose up -d

# Services started:
# - log-generator (port 8080)
# - prometheus (port 9090)
# - node-exporter (port 9100)
# - loki (port 3100)
# - promtail
# - grafana (port 3000)
```

**Network:** All services run on `loki-stack` network.

### Kubernetes (Production)

**Files:** [`k8s/*.yaml`](k8s/)

```bash
# Create namespace
kubectl apply -f k8s/00-namespace.yaml

# Deploy in order:
kubectl apply -f k8s/01-loki.yaml           # Log storage
kubectl apply -f k8s/02-promtail.yaml        # Log collection
kubectl apply -f k8s/03-grafana.yaml         # Visualization
kubectl apply -f k8s/04-log-generator.yaml   # Sample app
kubectl apply -f k8s/05-prometheus.yaml      # Metrics storage
kubectl apply -f k8s/06-node-exporter.yaml   # Node metrics
kubectl apply -f k8s/07-kube-state-metrics.yaml  # K8s metrics
```

**Namespace:** All resources deployed to `logging` namespace.

---

## Kubernetes Resources

### Namespace

```yaml
# k8s/00-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: logging
```

### Workload Types

| Component | Type | Replicas | Purpose |
|-----------|------|----------|---------|
| Loki | StatefulSet | 1 | Stateful log storage |
| Prometheus | StatefulSet | 1 | Stateful metrics storage |
| Grafana | Deployment | 1 | Stateless UI |
| Log Generator | Deployment | 1 | Stateless app |
| kube-state-metrics | Deployment | 1 | Stateless metrics |
| Promtail | DaemonSet | 1/node | Log collection per node |
| Node Exporter | DaemonSet | 1/node | Metrics per node |

### Services

| Service | Type | Port | Purpose |
|---------|------|------|---------|
| loki | ClusterIP | 3100 | Loki API |
| prometheus | ClusterIP | 9090 | Prometheus API |
| grafana | LoadBalancer | 3000 | Web UI |
| log-generator | ClusterIP | 8080 | App metrics |
| node-exporter | ClusterIP | 9100 | Node metrics |
| kube-state-metrics | ClusterIP | 8080 | K8s metrics |

---

## Metrics & Observability

### Application Metrics (Go App)

| Metric | Type | Labels | Description |
|--------|------|--------|-------------|
| `log_messages_total` | Counter | level | Total logs generated |
| `log_latency_seconds` | Histogram | - | Log processing latency |
| `active_connections` | Gauge | - | Simulated connections |
| `http_requests_total` | Counter | path, method | HTTP requests |
| `http_request_duration_seconds` | Histogram | path | Request duration |
| `errors_total` | Counter | type | Total errors |

### Infrastructure Metrics (Node Exporter)

| Metric | Description |
|--------|-------------|
| `node_cpu_seconds_total` | CPU time by mode |
| `node_memory_MemTotal_bytes` | Total memory |
| `node_memory_MemAvailable_bytes` | Available memory |
| `node_filesystem_size_bytes` | Filesystem size |
| `node_filesystem_avail_bytes` | Filesystem available |
| `node_network_receive_bytes_total` | Network received |
| `node_network_transmit_bytes_total` | Network transmitted |

### Kubernetes Metrics (kube-state-metrics)

| Metric | Description |
|--------|-------------|
| `kube_pod_info` | Pod metadata |
| `kube_pod_status_phase` | Pod status |
| `kube_deployment_status_replicas` | Deployment replicas |
| `kube_node_info` | Node information |
| `kube_persistentvolumeclaim_status` | PVC status |

---

## Quick Reference

### Port Forwarding (Kubernetes)

```bash
# Access Grafana
kubectl port-forward -n logging svc/grafana 3000:3000

# Access Prometheus
kubectl port-forward -n logging svc/prometheus 9090:9090

# Access Loki
kubectl port-forward -n logging svc/loki 3100:3100
```

### Useful Queries

**PromQL (Prometheus):**
```promql
# CPU usage
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Log rate by level
sum by (level) (rate(log_messages_total[5m]))

# Error rate
sum(rate(log_messages_total{level="error"}[5m]))
```

**LogQL (Loki):**
```logql
# All logs
{compose_service="log-generator"}

# Error logs
{compose_service="log-generator"} | json | level="ERROR"

# Log rate by level
sum by (level) (count_over_time({compose_service="log-generator"} | json [$__interval]))
```

---

## Summary

This observability platform follows the **three pillars of observability**:

1. **Logs** - Collected by Promtail, stored in Loki, queried with LogQL
2. **Metrics** - Scraped by Prometheus, stored in TSDB, queried with PromQL
3. **Traces** - (Future enhancement)

The architecture is designed for:
- **Scalability**: DaemonSets for per-node collection
- **Reliability**: StatefulSets for stateful components
- **Observability**: Every component exposes metrics
- **Simplicity**: Single namespace, clear separation of concerns