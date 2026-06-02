# PromQL and LogQL Query Guide for Grafana Dashboards

This guide explains the PromQL queries used in the Grafana dashboards and how to customize them for your specific needs.

## Table of Contents

1. [PromQL Basics](#promql-basics)
2. [Application Metrics Dashboard Queries](#application-metrics-dashboard-queries)
3. [Infrastructure Metrics Dashboard Queries](#infrastructure-metrics-dashboard-queries)
4. [LogQL Queries (Loki)](#logql-queries-loki)
5. [Customization Examples](#customization-examples)

---

## PromQL Basics

PromQL (Prometheus Query Language) is used to query metrics from Prometheus. Here are the fundamental concepts:

### Instant Vector vs Range Vector

- **Instant Vector**: Returns a single value per time series at a specific point in time
  ```promql
  log_messages_total
  ```

- **Range Vector**: Returns a range of values over a time period
  ```promql
  log_messages_total[5m]
  ```

### Common Functions

| Function | Description | Example |
|----------|-------------|---------|
| `rate()` | Per-second rate of increase | `rate(metric[5m])` |
| `irate()` | Instant per-second rate | `irate(metric[5m])` |
| `increase()` | Total increase over time | `increase(metric[5m])` |
| `sum()` | Aggregate values | `sum(metric)` |
| `avg()` | Average values | `avg(metric)` |
| `count()` | Count time series | `count(metric)` |
| `histogram_quantile()` | Calculate percentiles | `histogram_quantile(0.95, ...)` |

### Label Selectors

Filter metrics by labels:
```promql
# Exact match
log_messages_total{level="error"}

# Regex match
log_messages_total{level=~"error|warn"}

# Negative match
log_messages_total{level!="info"}

# Negative regex
log_messages_total{level!~"info|debug"}
```

### Aggregation Operators

Group and aggregate by labels:
```promql
# Sum by level
sum by (level) (log_messages_total)

# Average by instance
avg by (instance) (node_cpu_seconds_total)

# Multiple aggregations
sum by (level, instance) (log_messages_total)
```

---

## Application Metrics Dashboard Queries

### 1. Total Logs (5 minutes)

**Query:**
```promql
sum(increase(log_messages_total[5m]))
```

**Explanation:**
- `log_messages_total` - Counter metric tracking total log messages
- `increase(...[5m])` - Calculates the total increase over the last 5 minutes
- `sum(...)` - Aggregates across all label combinations

**Customization:**
```promql
# Change time window to 1 hour
sum(increase(log_messages_total[1h]))

# Filter by specific service
sum(increase(log_messages_total{job="my-service"}[5m]))

# Group by service
sum by (job) (increase(log_messages_total[5m]))
```

### 2. Error Logs (5 minutes)

**Query:**
```promql
sum(increase(log_messages_total{level="error"}[5m]))
```

**Explanation:**
- `{level="error"}` - Filters only error-level logs
- `increase(...[5m])` - Increase over 5 minutes
- `sum(...)` - Total across all instances

**Customization:**
```promql
# Include warning and error levels
sum(increase(log_messages_total{level=~"error|warn"}[5m]))

# Error rate per second
sum(rate(log_messages_total{level="error"}[5m]))

# Error percentage of total logs
sum(increase(log_messages_total{level="error"}[5m])) 
/ 
sum(increase(log_messages_total[5m])) * 100
```

### 3. Active Connections

**Query:**
```promql
active_connections
```

**Explanation:**
- Gauge metric showing current number of active connections
- Returns instant vector (current value)

**Customization:**
```promql
# Average connections over time
avg_over_time(active_connections[5m])

# Max connections in last hour
max_over_time(active_connections[1h])

# Group by instance
active_connections by (instance)
```

### 4. Goroutines

**Query:**
```promql
go_goroutines{job="log-generator"}
```

**Explanation:**
- Gauge metric showing number of Go goroutines
- `{job="log-generator"}` - Filters to specific job

**Customization:**
```promql
# All jobs
go_goroutines

# Group by instance
sum by (instance) (go_goroutines)

# Average goroutines over time
avg_over_time(go_goroutines{job="log-generator"}[5m])
```

### 5. Log Rate by Level

**Query:**
```promql
sum by (level) (rate(log_messages_total[5m]))
```

**Explanation:**
- `rate(log_messages_total[5m])` - Per-second rate of log messages
- `sum by (level)` - Groups results by log level

**Customization:**
```promql
# Different time window
sum by (level) (rate(log_messages_total[1m]))

# Include instance grouping
sum by (level, instance) (rate(log_messages_total[5m]))

# Filter specific levels
sum by (level) (rate(log_messages_total{level=~"error|warn"}[5m]))

# Use irate for more responsive graphs
sum by (level) (irate(log_messages_total[5m]))
```

### 6. Log Processing Latency (Percentiles)

**Query:**
```promql
# p50
histogram_quantile(0.50, rate(log_latency_seconds_bucket[5m]))

# p95
histogram_quantile(0.95, rate(log_latency_seconds_bucket[5m]))

# p99
histogram_quantile(0.99, rate(log_latency_seconds_bucket[5m]))
```

**Explanation:**
- `log_latency_seconds_bucket` - Histogram bucket metric
- `rate(...[5m])` - Rate of observations per bucket
- `histogram_quantile(0.95, ...)` - Calculates 95th percentile

**Customization:**
```promql
# Different percentile (e.g., 90th)
histogram_quantile(0.90, rate(log_latency_seconds_bucket[5m]))

# Average latency
rate(log_latency_seconds_sum[5m]) / rate(log_latency_seconds_count[5m])

# Group by service
histogram_quantile(0.95, sum by (le, job) (rate(log_latency_seconds_bucket[5m])))
```

---

## Infrastructure Metrics Dashboard Queries

### 1. CPU Usage

**Query:**
```promql
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Explanation:**
- `node_cpu_seconds_total{mode="idle"}` - CPU time spent in idle mode
- `irate(...[5m])` - Instant rate of change
- `avg by (instance)` - Average per instance
- `100 - (...)` - Converts idle percentage to usage percentage

**Customization:**
```promql
# CPU usage by mode (user, system, iowait)
avg by (instance, mode) (irate(node_cpu_seconds_total{mode!="idle"}[5m])) * 100

# Total CPU usage across all cores
(1 - avg(irate(node_cpu_seconds_total{mode="idle"}[5m]))) * 100

# CPU usage by specific mode
avg by (instance) (irate(node_cpu_seconds_total{mode="user"}[5m])) * 100
```

### 2. Memory Usage

**Query:**
```promql
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100
```

**Explanation:**
- `node_memory_MemTotal_bytes` - Total memory
- `node_memory_MemAvailable_bytes` - Available memory
- `(1 - available/total) * 100` - Used memory percentage

**Customization:**
```promql
# Memory used in GB
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / 1024 / 1024 / 1024

# Memory usage by instance
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 by (instance)

# Cache/buffer memory
node_memory_Buffers_bytes + node_memory_Cached_bytes
```

### 3. Disk I/O

**Query:**
```promql
# Read rate
rate(node_disk_read_bytes_total[5m])

# Write rate
rate(node_disk_written_bytes_total[5m])
```

**Customization:**
```promql
# Total disk I/O
rate(node_disk_read_bytes_total[5m]) + rate(node_disk_written_bytes_total[5m])

# I/O by device
sum by (device) (rate(node_disk_read_bytes_total[5m]))

# IOPS (I/O operations per second)
rate(node_disk_reads_completed_total[5m]) + rate(node_disk_writes_completed_total[5m])
```

### 4. Network Traffic

**Query:**
```promql
# Receive rate
rate(node_network_receive_bytes_total[5m])

# Transmit rate
rate(node_network_transmit_bytes_total[5m])
```

**Customization:**
```promql
# Filter specific interface
rate(node_network_receive_bytes_total{device="eth0"}[5m])

# Total network traffic
sum(rate(node_network_receive_bytes_total[5m])) by (instance)

# Network errors
rate(node_network_receive_errs_total[5m]) + rate(node_network_transmit_errs_total[5m])
```

### 5. Disk Usage

**Query:**
```promql
(1 - (node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"} / node_filesystem_size_bytes{fstype!~"tmpfs|overlay"})) * 100
```

**Explanation:**
- `node_filesystem_avail_bytes` - Available space
- `node_filesystem_size_bytes` - Total size
- `fstype!~"tmpfs|overlay"` - Excludes temporary filesystems

**Customization:**
```promql
# Specific mount point
(1 - (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"})) * 100

# Available space in GB
node_filesystem_avail_bytes / 1024 / 1024 / 1024

# Group by mount point
(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100 by (mountpoint)
```

---

## LogQL Queries (Loki)

LogQL is used to query logs from Loki. It has two main types: log queries and metric queries.

### Basic Log Queries

```logql
# Simple log query
{compose_service="log-generator"}

# Multiple label filters
{compose_service="log-generator", level="ERROR"}

# Regex match
{compose_service="log-generator"} |= "error"

# Case-insensitive match
{compose_service="log-generator"} |~ "(?i)error"

# Negative match
{compose_service="log-generator"} != "debug"
```

### Log Parsing

```logql
# JSON parsing
{compose_service="log-generator"} | json

# Extract specific fields
{compose_service="log-generator"} | json | level="ERROR"

# Logfmt parsing
{job="myapp"} | logfmt

# Regular expression parsing
{job="myapp"} | regexp "(?P<method>\\w+) (?P<path>\\S+)"
```

### Metric Queries

Convert logs to metrics using aggregations:

```logql
# Count logs over time
count_over_time({compose_service="log-generator"}[5m])

# Count by level
sum by (level) (count_over_time({compose_service="log-generator"} | json [5m]))

# Rate of logs
rate({compose_service="log-generator"}[5m])

# Bytes processed
bytes_over_time({compose_service="log-generator"}[5m])
```

### Dashboard LogQL Examples

#### Error Count
```logql
sum(count_over_time({compose_service="log-generator"} | json | level="ERROR" [$__interval]))
```

**Customization:**
```logql
# Count specific error patterns
sum(count_over_time({compose_service="log-generator"} | json | message=~".*timeout.*" [$__interval]))

# Error rate per second
sum(rate({compose_service="log-generator"} | json | level="ERROR" [5m]))
```

#### Log Rate by Level
```logql
sum by (level) (count_over_time({compose_service="log-generator"} | json [$__interval]))
```

**Customization:**
```logql
# Log rate per second
sum by (level) (rate({compose_service="log-generator"} | json [5m]))

# Filter specific levels
sum by (level) (count_over_time({compose_service="log-generator"} | json | level=~"ERROR|WARN" [$__interval]))

# Group by multiple labels
sum by (level, instance) (count_over_time({compose_service="log-generator"} | json [$__interval]))
```

---

## Customization Examples

### Adding New Panels

To add a new panel to your dashboard, add a new object to the `panels` array in the JSON:

```json
{
  "datasource": {
    "type": "prometheus",
    "uid": "${datasource}"
  },
  "fieldConfig": {
    "defaults": {
      "color": {"mode": "palette-classic"},
      "unit": "short"
    },
    "overrides": []
  },
  "gridPos": {
    "h": 8,
    "w": 12,
    "x": 0,
    "y": 0
  },
  "id": 100,
  "targets": [
    {
      "expr": "your_promql_query_here",
      "refId": "A"
    }
  ],
  "title": "Panel Title",
  "type": "timeseries"
}
```

### Common Customizations

#### 1. Change Time Range in Queries

Replace `[5m]` with:
- `[1m]` - 1 minute (more granular, more noise)
- `[15m]` - 15 minutes (smoother)
- `[1h]` - 1 hour (long-term trends)
- `[$__interval]` - Dynamic based on dashboard time range

#### 2. Add Alert Thresholds

```json
"fieldConfig": {
  "defaults": {
    "thresholds": {
      "mode": "absolute",
      "steps": [
        {"color": "green", "value": null},
        {"color": "yellow", "value": 70},
        {"color": "red", "value": 90}
      ]
    }
  }
}
```

#### 3. Filter by Kubernetes Labels

```promql
# Filter by namespace
sum by (pod) (container_cpu_usage_seconds_total{namespace="default"})

# Filter by deployment
kube_deployment_status_replicas_available{deployment="my-app"}

# Filter by label selector
kube_pod_info{label_app="my-app"}
```

#### 4. Create Recording Rules

For frequently used queries, create recording rules in Prometheus:

```yaml
groups:
  - name: app_metrics
    rules:
      - record: app:log_rate:5m
        expr: sum by (level) (rate(log_messages_total[5m]))
      
      - record: app:error_rate:5m
        expr: sum(rate(log_messages_total{level="error"}[5m]))
```

Then use the recording rule in your dashboard:
```promql
app:log_rate:5m
```

---

## Best Practices

1. **Use Recording Rules** for complex queries that are used frequently
2. **Label Appropriately** - Use consistent label names across metrics
3. **Choose Right Time Windows** - Balance between granularity and noise
4. **Use Variables** - Create dashboard variables for dynamic filtering
5. **Set Appropriate Thresholds** - Based on your SLOs and SLAs

### Dashboard Variables

Add variables to make dashboards dynamic:

```json
"templating": {
  "list": [
    {
      "name": "datasource",
      "type": "datasource",
      "query": "prometheus",
      "refresh": 1
    },
    {
      "name": "level",
      "type": "query",
      "query": "label_values(log_messages_total, level)",
      "refresh": 1
    },
    {
      "name": "job",
      "type": "query",
      "query": "label_values(job)",
      "refresh": 1
    }
  ]
}
```

Use variables in queries:
```promql
sum by (${level}) (rate(log_messages_total{job="${job}"}[5m]))
```

---

## Additional Resources

- [Prometheus Query Documentation](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Loki LogQL Documentation](https://grafana.com/docs/loki/latest/logql/)
- [Grafana Dashboard Documentation](https://grafana.com/docs/grafana/latest/dashboards/)
- [Node Exporter Metrics](https://github.com/prometheus/node_exporter)