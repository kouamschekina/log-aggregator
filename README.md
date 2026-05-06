# Centralized Logging System with Grafana Loki

This project sets up a complete log aggregation pipeline using the Grafana Loki stack (Promtail, Loki, Grafana) and a custom Go application that generates structured JSON logs.

## Architecture

1. **Log Generator (Go App)**: Continuously produces JSON logs with different severity levels (INFO, ERROR, DEBUG) to `stdout`.
2. **Promtail**: Collects logs from Docker containers by reading the Docker daemon's log files. It attaches labels such as the container name and docker-compose service name.
3. **Loki**: Acts as the log storage backend. It indexes labels and stores the log lines. Configured to persist data locally.
4. **Grafana**: Provides the visualization dashboard to query and monitor the logs stored in Loki using LogQL.

## Prerequisites

- Docker
- Docker Compose

## Setup Instructions

1. Clone or navigate to the directory containing this project.
2. Start the entire stack with Docker Compose:
   ```bash
   docker compose up -d --build
   ```
3. Wait a few seconds for the services to initialize and the Go application to start generating logs.
4. Access Grafana at [http://localhost:3000](http://localhost:3000).
   *(Authentication is disabled, you will be automatically logged in as an Admin)*

## Viewing Logs

1. In Grafana, navigate to the **Explore** view (the compass icon on the left sidebar).
2. Ensure **Loki** is selected as the data source in the top left dropdown.
3. Use the **Label filters** or enter a LogQL query to search your logs.

### Example LogQL Queries

- **View all logs from the log generator**:
  ```logql
  {compose_service="log-generator"}
  ```

- **Filter logs by ERROR level** (parsing JSON):
  ```logql
  {compose_service="log-generator"} | json | level="ERROR"
  ```

- **Filter logs by INFO level**:
  ```logql
  {compose_service="log-generator"} | json | level="INFO"
  ```

- **Search for a specific keyword** (e.g., "timeout"):
  ```logql
  {compose_service="log-generator"} |= "timeout"
  ```

## Persistence

Loki is configured to store its data in the `loki-data` Docker volume. If you restart or recreate the containers, your logs will persist.

To completely reset the environment and delete the logs, run:
```bash
docker compose down -v
```

## Kubernetes Deployment (Optional Enhancement)

If you prefer to run this stack on a Kubernetes cluster (such as Minikube or Kind), you can use the provided Kubernetes manifests.

### Setup Instructions

1. Start your local cluster (e.g., `minikube start`).
2. Build the log generator image and load it into your cluster:
   ```bash
   docker build -t log-aggregator-log-generator:latest ./app
   minikube image load log-aggregator-log-generator:latest
   ```
3. Apply the manifests in the `k8s/` directory:
   ```bash
   kubectl apply -f k8s/
   ```
4. Wait for the pods to become ready:
   ```bash
   kubectl get pods -n logging
   ```
5. Access Grafana by port-forwarding:
   ```bash
   kubectl port-forward svc/grafana 3000:3000 -n logging
   ```
6. Open [http://localhost:3000](http://localhost:3000) and query your logs.

*Note: The Promtail DaemonSet is configured to auto-discover all Pod logs using `kubernetes_sd_configs`.*
