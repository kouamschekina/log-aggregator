#!/bin/bash

# Deploy Log Aggregation Stack (without Prometheus)
# This script deploys only the logging components: Loki, Promtail, Grafana, Log Generator

set -e

echo "=== Deploying Log Aggregation Stack ==="

# Create namespace
echo "Creating namespace..."
kubectl apply -f k8s/00-namespace.yaml

# Deploy Loki
echo "Deploying Loki..."
kubectl apply -f k8s/01-loki.yaml

# Deploy Promtail
echo "Deploying Promtail..."
kubectl apply -f k8s/02-promtail.yaml

# Deploy Grafana
echo "Deploying Grafana..."
kubectl apply -f k8s/03-grafana.yaml

# Deploy Log Generator
echo "Deploying Log Generator..."
kubectl apply -f k8s/04-log-generator.yaml

echo ""
echo "=== Waiting for pods to be ready ==="
kubectl wait --for=condition=ready pod -l app=loki -n logging --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=grafana -n logging --timeout=120s || true
kubectl wait --for=condition=ready pod -l app=log-generator -n logging --timeout=120s || true

echo ""
echo "=== Pod Status ==="
kubectl get pods -n logging

echo ""
echo "=== Services ==="
kubectl get services -n logging

echo ""
echo "=== Access the Services ==="
echo "Grafana: http://<EXTERNAL-IP>:3000"
echo "Loki: http://<EXTERNAL-IP>:3100"
echo ""
echo "To get the external IP, run:"
echo "  kubectl get services -n logging"
echo ""
echo "If using k3s without LoadBalancer support, use port-forward:"
echo "  kubectl port-forward -n logging svc/grafana 3000:3000"
echo "  kubectl port-forward -n logging svc/loki 3100:3100"