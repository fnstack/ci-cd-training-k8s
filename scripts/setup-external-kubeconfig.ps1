# External Kubeconfig Setup Script - PowerShell Version
# This script sets up kubectl access to the remote Minikube cluster

# Set error handling
$ErrorActionPreference = "Stop"

# Configuration variables
$REMOTE_HOST = "mini-kube.arpce.fnstack.dev"
$REMOTE_USER = "ubuntu"
$SSH_KEY = ".ssh\k8s-private-key.pem"
$EXTERNAL_DOMAIN = "mini-kube.arpce.fnstack.dev"
$EXTERNAL_PORT = "8443"

Write-Host "🚀 Setting up external kubectl access to Minikube cluster..." -ForegroundColor Green

# Check if SSH key exists
if (-not (Test-Path $SSH_KEY)) {
    Write-Host "❌ SSH key not found: $SSH_KEY" -ForegroundColor Red
    Write-Host "Please ensure the SSH key is available at the correct location." -ForegroundColor Yellow
    exit 1
}

# Create .kube directory if it doesn't exist
$kubeDir = "$env:USERPROFILE\.kube"
if (-not (Test-Path $kubeDir)) {
    New-Item -ItemType Directory -Path $kubeDir -Force | Out-Null
}

Write-Host "📥 Downloading kubeconfig from remote server..." -ForegroundColor Blue

# SSH into remote server and generate kubeconfig
$tempKubeconfig = "$env:TEMP\kubeconfig-temp.yaml"
try {
    $sshCommand = "ssh -i `"$SSH_KEY`" `"$REMOTE_USER@$REMOTE_HOST`" `"kubectl config view --raw --minify --flatten`""
    Invoke-Expression $sshCommand | Out-File -FilePath $tempKubeconfig -Encoding UTF8
    
    if (-not (Test-Path $tempKubeconfig) -or (Get-Content $tempKubeconfig).Count -eq 0) {
        throw "Failed to download kubeconfig"
    }
}
catch {
    Write-Host "❌ Failed to download kubeconfig from remote server" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "🔧 Configuring kubeconfig for external access..." -ForegroundColor Yellow

# Extract certificate data from temp file
$clientCertData = (Select-String -Path $tempKubeconfig -Pattern "client-certificate-data:").Line -replace ".*client-certificate-data:\s*", ""
$clientKeyData = (Select-String -Path $tempKubeconfig -Pattern "client-key-data:").Line -replace ".*client-key-data:\s*", ""

if (-not $clientCertData -or -not $clientKeyData) {
    Write-Host "❌ Failed to extract certificate data from kubeconfig" -ForegroundColor Red
    exit 1
}

# Create the kubeconfig content
$kubeconfigContent = @"
apiVersion: v1
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://$EXTERNAL_DOMAIN`:$EXTERNAL_PORT
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
    client-certificate-data: $clientCertData
    client-key-data: $clientKeyData
"@

# Write the kubeconfig file
$kubeconfigPath = "$kubeDir\config"
$kubeconfigContent | Out-File -FilePath $kubeconfigPath -Encoding UTF8

# Clean up temp file
if (Test-Path $tempKubeconfig) {
    Remove-Item $tempKubeconfig -Force
}

# Set proper permissions (Windows equivalent)
$acl = Get-Acl $kubeconfigPath
$acl.SetAccessRuleProtection($true, $false)  # Remove inherited permissions
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($env:USERNAME, "FullControl", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl -Path $kubeconfigPath -AclObject $acl

Write-Host "✅ Kubeconfig setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "🧪 Testing connection..." -ForegroundColor Blue

# Test the connection
try {
    $nodes = kubectl get nodes 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Successfully connected to Minikube cluster!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📊 Cluster information:" -ForegroundColor Cyan
        kubectl get nodes
        Write-Host ""
        Write-Host "🎉 Setup complete! You can now use kubectl commands from this machine." -ForegroundColor Green
        Write-Host "💡 The configuration is persistent across PowerShell sessions." -ForegroundColor Yellow
    }
    else {
        throw "kubectl command failed"
    }
}
catch {
    Write-Host "❌ Failed to connect to the cluster" -ForegroundColor Red
    Write-Host "Please check:" -ForegroundColor Yellow
    Write-Host "  1. The remote server is accessible" -ForegroundColor White
    Write-Host "  2. kubectl is installed and in PATH" -ForegroundColor White
    Write-Host "  3. The API proxy service is running on the remote server" -ForegroundColor White
    Write-Host "  4. Port $EXTERNAL_PORT is open in the firewall" -ForegroundColor White
    exit 1
}

Write-Host ""
Write-Host "📝 Example commands you can now run:" -ForegroundColor Cyan
Write-Host "  kubectl get nodes" -ForegroundColor White
Write-Host "  kubectl get pods --all-namespaces" -ForegroundColor White
Write-Host "  kubectl cluster-info" -ForegroundColor White
Write-Host "  kubectl create deployment test-app --image=nginx" -ForegroundColor White