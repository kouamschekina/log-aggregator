terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

locals {
  master_cloud_init = templatefile("${path.module}/cloud-init-master.yaml", {
    K3S_TOKEN   = var.k3s_token
    K3S_VERSION = var.k3s_version
  })
}

resource "local_file" "master_ci" {
  filename = "${path.module}/rendered-master-cloud-init.yaml"
  content  = local.master_cloud_init
}

resource "null_resource" "master" {
  triggers = {
    ci_checksum = sha256(local.master_cloud_init)
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      if ! multipass info k3s-master >/dev/null 2>&1; then
        multipass launch 22.04 --name k3s-master --cpus 2 --memory 4G --disk 10G --cloud-init ${local_file.master_ci.filename}
      fi
    EOT
    interpreter = ["/bin/bash", "-lc"]
  }
}

resource "local_file" "worker_ci" {
  filename = "${path.module}/rendered-worker-cloud-init.yaml"
  content = templatefile("${path.module}/cloud-init-worker.yaml", {
    K3S_TOKEN   = var.k3s_token
    K3S_VERSION = var.k3s_version
    SERVER_IP   = "PLACEHOLDER_IP"
  })
  depends_on = [null_resource.master]
}

resource "null_resource" "worker" {
  depends_on = [null_resource.master, local_file.worker_ci]

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      
      # Get master IP
      MASTER_IP=$(multipass info k3s-master --format json | jq -r '.info["k3s-master"].ipv4[0]')
      echo "Master IP: $MASTER_IP"
      
      # Wait for master API to be ready
      echo "Waiting for K3s API server to be ready..."
      for i in {1..60}; do
        if timeout 2 bash -c "</dev/tcp/$MASTER_IP/6443" 2>/dev/null; then
          echo "K3s API server is ready!"
          break
        fi
        echo "Waiting... ($i/60)"
        sleep 5
      done
      
      # Create worker cloud-init with actual master IP
      cat > ${local_file.worker_ci.filename} <<EOF
#cloud-config
packages:
  - curl
  - git
  - apt-transport-https
  - ca-certificates
  - gnupg
  - jq
  - nfs-common
write_files:
  - path: /usr/local/bin/install-k3s-agent.sh
    permissions: '0755'
    content: |
      #!/usr/bin/env bash
      set -euo pipefail
      if systemctl is-active --quiet k3s-agent; then
        exit 0
      fi
      if [[ -n "${var.k3s_version}" ]]; then
        export INSTALL_K3S_VERSION="${var.k3s_version}"
      fi
      echo "Installing K3s agent..."
      curl -sfL https://get.k3s.io | K3S_URL="https://$MASTER_IP:6443" K3S_TOKEN="${var.k3s_token}" sh -
      echo "K3s agent installation complete"
runcmd:
  - [ bash, -lc, 'sudo bash /usr/local/bin/install-k3s-agent.sh' ]
EOF
      
      # Launch worker if it doesn't exist
      if ! multipass info k3s-worker >/dev/null 2>&1; then
        echo "Creating k3s-worker VM..."
        multipass launch 22.04 --name k3s-worker --cpus 2 --memory 4G --disk 10G --cloud-init ${local_file.worker_ci.filename}
        echo "Worker VM created successfully"
      else
        echo "Worker VM already exists"
      fi
    EOT
    interpreter = ["/bin/bash", "-lc"]
  }
}
