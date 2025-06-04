# ArgoCD Installation Script using Helm (PowerShell)
# This script installs ArgoCD using the official Helm chart with our custom values

param(
    [switch]$Uninstall,
    [string]$Namespace = "argocd",
    [string]$ValuesFile = "argocd-values.yaml"
)

# Colors for output
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$NC = "`e[0m"

function Write-Status {
    param($Message)
    Write-Host "${BLUE}[INFO]${NC} $Message"
}

function Write-Success {
    param($Message)
    Write-Host "${GREEN}[SUCCESS]${NC} $Message"
}

function Write-Warning {
    param($Message)
    Write-Host "${YELLOW}[WARNING]${NC} $Message"
}

function Write-Error {
    param($Message)
    Write-Host "${RED}[ERROR]${NC} $Message"
}

# Check if kubectl is available
if (!(Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Error "kubectl is not installed or not in PATH"
    exit 1
}

# Check if helm is available
if (!(Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Error "helm is not installed or not in PATH"
    exit 1
}

# Check if the dependent_services node exists and is ready
Write-Status "Checking cluster nodes..."
$nodeCheck = kubectl get nodes -l type=dependent_services --no-headers 2>$null
if (!$nodeCheck) {
    Write-Warning "No nodes found with label 'type=dependent_services'"
    Write-Status "Available nodes:"
    kubectl get nodes --show-labels
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne "y" -and $continue -ne "Y") {
        Write-Status "Installation cancelled"
        exit 0
    }
} else {
    Write-Success "Found dependent_services node: $($nodeCheck.Split()[0])"
}

if ($Uninstall) {
    Write-Status "Uninstalling ArgoCD..."
    helm uninstall argocd -n $Namespace
    kubectl delete namespace $Namespace --ignore-not-found=true
    Write-Success "ArgoCD uninstalled successfully! 🗑️"
    exit 0
}

Write-Status "🚀 Installing ArgoCD with GitOps configuration..."

# Create namespace
Write-Status "Creating $Namespace namespace..."
kubectl create namespace $Namespace --dry-run=client -o yaml | kubectl apply -f -

# Add ArgoCD Helm repository
Write-Status "Adding ArgoCD Helm repository..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD with custom values
Write-Status "Installing ArgoCD with custom configuration..."
Write-Status "This may take several minutes - please wait..."

try {
    helm upgrade --install argocd argo/argo-cd `
        --namespace $Namespace `
        --values $ValuesFile `
        --timeout 15m `
        --wait `
        --debug 2>&1 | Tee-Object -Variable helmOutput
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Helm installation failed!"
        Write-Host $helmOutput
        exit 1
    }
} catch {
    Write-Error "Failed to install ArgoCD: $_"
    exit 1
}

# Wait for ArgoCD server to be ready
Write-Status "Waiting for ArgoCD server to be ready..."
$retryCount = 0
$maxRetries = 30
do {
    $readyPods = kubectl get pods -n $Namespace -l app.kubernetes.io/name=argocd-server --no-headers 2>$null | Where-Object { $_ -match "Running" }
    if ($readyPods) {
        Write-Success "ArgoCD server is ready!"
        break
    }
    Start-Sleep 10
    $retryCount++
    Write-Status "Waiting for ArgoCD server... ($retryCount/$maxRetries)"
} while ($retryCount -lt $maxRetries)

if ($retryCount -eq $maxRetries) {
    Write-Warning "ArgoCD server may not be fully ready yet. Check pods manually."
}

# Get the initial admin password
Write-Status "Retrieving ArgoCD admin password..."
try {
    Start-Sleep 5  # Give a moment for secret to be created
    $AdminPasswordBytes = kubectl -n $Namespace get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>$null
    if ($AdminPasswordBytes) {
        $AdminPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($AdminPasswordBytes))
    } else {
        $AdminPassword = "Password secret not found - check manually"
    }
} catch {
    $AdminPassword = "Error retrieving password - check manually"
}

# Get node IP for access
try {
    $NodeIP = kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>$null
    if (!$NodeIP) { $NodeIP = "localhost" }
} catch {
    $NodeIP = "localhost"
}

Write-Success "ArgoCD installation completed successfully! 🎉"
Write-Host ""
Write-Host "📋 Access Information:" -ForegroundColor Cyan
Write-Host "   URL: http://${NodeIP}:30080"
Write-Host "   Username: admin"
Write-Host "   Password: $AdminPassword"
Write-Host ""
Write-Host "🔧 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Access ArgoCD UI at the URL above"
Write-Host "   2. Change the default admin password"
Write-Host "   3. Deploy ArgoCD applications:"
Write-Host "      kubectl apply -f applications/"
Write-Host "   4. Configure repository connections if needed"
Write-Host ""
Write-Host "💡 Useful Commands:" -ForegroundColor Cyan
Write-Host "   # Get admin password again:"
Write-Host "   kubectl -n $Namespace get secret argocd-initial-admin-secret -o jsonpath=`"{.data.password}`" | base64 -d"
Write-Host ""
Write-Host "   # Forward port for local access:"
Write-Host "   kubectl port-forward svc/argocd-server -n $Namespace 8080:443"
Write-Host ""
Write-Host "   # Check ArgoCD pods:"
Write-Host "   kubectl get pods -n $Namespace"
Write-Host ""
Write-Host "   # Uninstall ArgoCD:"
Write-Host "   .\install-argocd.ps1 -Uninstall"
