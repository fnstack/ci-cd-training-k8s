#!/bin/bash

# External Kubeconfig Setup Script
# This script sets up kubectl access to the remote Minikube cluster

set -e

REMOTE_HOST="mini-kube.arpce.fnstack.dev"
REMOTE_USER="ubuntu"
SSH_KEY=".ssh/k8s-private-key.pem"
EXTERNAL_DOMAIN="mini-kube.arpce.fnstack.dev"
EXTERNAL_PORT="8443"

echo "🚀 Setting up external kubectl access to Minikube cluster..."

# Check if SSH key exists
if [ ! -f "$SSH_KEY" ]; then
    echo "❌ SSH key not found: $SSH_KEY"
    echo "Please ensure the SSH key is available at the correct location."
    exit 1
fi

# Create .kube directory if it doesn't exist
mkdir -p ~/.kube

echo "📥 Downloading kubeconfig from remote server..."

# SSH into remote server and generate kubeconfig
ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" \
    "kubectl config view --raw --minify --flatten" > /tmp/kubeconfig-temp.yaml

if [ $? -ne 0 ]; then
    echo "❌ Failed to download kubeconfig from remote server"
    exit 1
fi

echo "🔧 Configuring kubeconfig for external access..."

# Update the server URL and disable TLS verification
cat > ~/.kube/config << EOF
apiVersion: v1
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://$EXTERNAL_DOMAIN:$EXTERNAL_PORT
  name: minikube-external
contexts:
- context:
    cluster: minikube-external
    namespace: default
    user: minikube-external-user
  name: minikube-external
current-context: minikube-external
kind: Config
users:
- name: minikube-external-user
  user:
EOF

# Extract and add the client certificate and key from the temp file
echo "    client-certificate-data: $(grep 'client-certificate-data:' /tmp/kubeconfig-temp.yaml | cut -d' ' -f6)" >> ~/.kube/config
echo "    client-key-data: $(grep 'client-key-data:' /tmp/kubeconfig-temp.yaml | cut -d' ' -f6)" >> ~/.kube/config

# Clean up temp file
rm -f /tmp/kubeconfig-temp.yaml

# Set proper permissions
chmod 600 ~/.kube/config

echo "✅ Kubeconfig setup complete!"
echo ""
echo "🧪 Testing connection..."

# Test the connection
if kubectl get nodes >/dev/null 2>&1; then
    echo "✅ Successfully connected to Minikube cluster!"
    echo ""
    echo "📊 Cluster information:"
    kubectl get nodes
    echo ""
    echo "🎉 Setup complete! You can now use kubectl commands from this machine."
    echo "💡 The configuration is persistent across shell sessions."
else
    echo "❌ Failed to connect to the cluster"
    echo "Please check:"
    echo "  1. The remote server is accessible"
    echo "  2. The API proxy service is running: sudo systemctl status k8s-api-proxy"
    echo "  3. Port $EXTERNAL_PORT is open in the firewall"
    exit 1
fi

echo ""
echo "📝 Example commands you can now run:"
echo "  kubectl get nodes"
echo "  kubectl get pods --all-namespaces"
echo "  kubectl cluster-info"
echo "  kubectl create deployment test-app --image=nginx"