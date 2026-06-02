# K3s Cluster with Multipass and Terraform

A simple Terraform setup that creates a K3s Kubernetes cluster using Multipass VMs.

## 🚀 Features

- **One-command setup**: Creates master + worker nodes automatically
- **Lightweight**: Uses K3s for minimal resource usage
- **Local development**: Perfect for testing Kubernetes workloads locally
- **Cross-platform**: Works on Linux, macOS, and Windows

## 📋 Prerequisites

Install these tools before running:

- **Multipass**: [Download here](https://multipass.run/)
- **Terraform**: [Download here](https://terraform.io/downloads)
- **jq**: JSON processor
  - Ubuntu/Debian: `sudo apt install jq`
  - macOS: `brew install jq`
  - Windows: `choco install jq`

## ⚡ Quick Start

### Option 1: Automated Setup
```bash
git clone <your-repo-url>
cd k3s-multipass-terraform
./setup-k3s.sh
```

### Option 2: Manual Setup
```bash
git clone <your-repo-url>
cd k3s-multipass-terraform
terraform init
terraform apply -auto-approve

# Get kubeconfig
multipass exec k3s-master -- sudo cat /etc/rancher/k3s/k3s.yaml > k3s-kubeconfig.yaml
sed -i 's/127.0.0.1/$(multipass info k3s-master --format json | jq -r '.info["k3s-master"].ipv4[0]')/g' k3s-kubeconfig.yaml

# Use the cluster
export KUBECONFIG=./k3s-kubeconfig.yaml
kubectl get nodes
```

## 🏗️ What Gets Created

| Resource | Specs | Purpose |
|----------|-------|---------|
| **k3s-master** | 2 CPUs, 4GB RAM, 10GB disk | Control plane node |
| **k3s-worker** | 2 CPUs, 4GB RAM, 10GB disk | Worker node |

Both VMs run **Ubuntu 22.04 LTS** with K3s automatically configured.

## ⚙️ Customization

Edit `variables.tf` to modify:
- **k3s_version**: K3s version to install
- **k3s_token**: Cluster join token

Edit `main.tf` to change VM specs:
- CPU count: `--cpus 2`
- Memory: `--memory 4G` 
- Disk: `--disk 10G`

## 🧪 Testing Your Cluster

```bash
# Check nodes
kubectl get nodes

# Deploy a test app
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=NodePort

# Check pods
kubectl get pods
```

## 🧹 Cleanup

```bash
# Destroy infrastructure
terraform destroy -auto-approve

# Clean up VMs (if needed)
multipass delete k3s-master k3s-worker
multipass purge
```

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|
| VM creation fails | `multipass delete --all && multipass purge` |
| Network issues | Check firewall settings |
| K3s not starting | `multipass shell k3s-master` and check logs |

### Common Commands
```bash
# Check VM status
multipass list

# Access VMs
multipass shell k3s-master
multipass shell k3s-worker

# View VM info
multipass info k3s-master
```

## 📁 Repository Structure

```
.
├── README.md                 # This file
├── main.tf                   # Main Terraform configuration
├── variables.tf              # Variable definitions
├── cloud-init-master.yaml   # Master node cloud-init
├── cloud-init-worker.yaml   # Worker node cloud-init
├── setup-k3s.sh            # Automated setup script
└── .gitignore               # Git ignore rules
```

## 🤝 Contributing

Feel free to submit issues and pull requests to improve this setup!
