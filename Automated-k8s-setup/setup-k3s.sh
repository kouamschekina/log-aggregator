#!/bin/bash
set -euo pipefail

echo "🚀 Setting up K3s cluster with Terraform and Multipass..."

# Check prerequisites
command -v multipass >/dev/null 2>&1 || { echo "❌ Multipass is required but not installed. Visit https://multipass.run/"; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform is required but not installed. Visit https://terraform.io/downloads"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "❌ jq is required but not installed. Run: sudo apt install jq"; exit 1; }

echo "✅ Prerequisites check passed"

# Clean up any existing state
echo "🧹 Cleaning up any existing state..."
rm -f terraform.tfstate* k3s-kubeconfig.yaml rendered-*.yaml

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Apply configuration
echo "🏗️  Creating K3s cluster..."
terraform apply -auto-approve

# Wait a moment for everything to settle
echo "⏳ Waiting for cluster to stabilize..."
sleep 10

# Get master IP
MASTER_IP=$(multipass info k3s-master --format json | jq -r '.info["k3s-master"].ipv4[0]')
echo "📍 Master IP: $MASTER_IP"

# Extract kubeconfig
echo "🔑 Setting up kubeconfig..."
multipass exec k3s-master -- sudo cat /etc/rancher/k3s/k3s.yaml > k3s-kubeconfig.yaml
sed -i "s/127.0.0.1/$MASTER_IP/g" k3s-kubeconfig.yaml

# Test the cluster
echo "🧪 Testing cluster..."
export KUBECONFIG=./k3s-kubeconfig.yaml
kubectl get nodes

echo ""
echo "🎉 K3s cluster is ready!"
echo ""
echo "To use the cluster, run:"
echo "  export KUBECONFIG=./k3s-kubeconfig.yaml"
echo "  kubectl get nodes"
echo ""
echo "To access VMs directly:"
echo "  multipass shell k3s-master"
echo "  multipass shell k3s-worker"
echo ""
echo "To clean up:"
echo "  terraform destroy -auto-approve"
echo "  multipass delete k3s-master k3s-worker && multipass purge"
