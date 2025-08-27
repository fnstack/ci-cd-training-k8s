# Kubectl Configuration Setup

## Overview
This guide explains how to configure kubectl to connect to the Kubernetes cluster after retrieving the kubectl binary from the master node.

## Prerequisites
- kubectl binary installed (already completed)
- SSH access to the k8s master node with private key: `.ssh/k8s-private-key.pem`
- Master node: `k8s-master.arpce.fnstack.dev`
- Username: `ubuntu`

## Configuration Steps

### 1. Retrieve Cluster Configuration
Copy the kubeconfig file from the master node:

```bash
# Copy kubeconfig from master node
scp -i .ssh/k8s-private-key.pem ubuntu@k8s-master.arpce.fnstack.dev:~/.kube/config ~/.kube/config

# Alternative: Copy from /etc/kubernetes/admin.conf if available
scp -i .ssh/k8s-private-key.pem ubuntu@k8s-master.arpce.fnstack.dev:/etc/kubernetes/admin.conf ~/.kube/config
```

### 2. Create .kube Directory (if it doesn't exist)
```bash
mkdir -p ~/.kube
```

### 3. Set Proper Permissions
```bash
chmod 600 ~/.kube/config
```

### 4. Verify Connection
```bash
# Check cluster info
kubectl cluster-info

# List nodes
kubectl get nodes

# Check current context
kubectl config current-context

# View all contexts
kubectl config get-contexts
```

## Troubleshooting

### Connection Issues
If you encounter connection issues:

1. **Check cluster endpoint**: Ensure the server URL in the config points to the correct master node
2. **Verify certificates**: Make sure certificate data is correctly copied
3. **Network connectivity**: Test SSH connection to master node

### Update Server URL
If the kubeconfig contains localhost or internal IPs, update the server URL:

```bash
kubectl config set-cluster <cluster-name> --server=https://k8s-master.arpce.fnstack.dev:6443
```

### Alternative: Use kubectl proxy
For development/testing, you can use kubectl proxy from the master node:

```bash
# On master node
kubectl proxy --address=0.0.0.0 --port=8080 --accept-hosts='^.*$'

# From local machine
kubectl --server=http://k8s-master.arpce.fnstack.dev:8080 get nodes
```

## Verification Commands

Once configured, test these commands to verify everything works:

```bash
# Basic cluster information
kubectl version
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
kubectl get pods --all-namespaces
```

## Notes
- kubectl version: v1.28.15
- Keep the SSH private key secure and with proper permissions (600)
- The kubeconfig file contains sensitive authentication information