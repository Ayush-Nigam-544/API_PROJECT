#!/usr/bin/env pwsh
# Kubernetes Deployment Script
# This script deploys the Student API application stack to Kubernetes

param(
    [switch]$SkipBuild = $false,
    [switch]$Verbose = $false,
    [string]$Namespace = "all"
)

# Colors for output
$Green = "`e[32m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-Status {
    param($Message, $Color = $Green)
    Write-Host "$Color🚀 $Message$Reset"
}

function Write-Info {
    param($Message)
    Write-Host "$Blue💡 $Message$Reset"
}

function Write-Warning {
    param($Message)
    Write-Host "$Yellow⚠️  $Message$Reset"
}

function Write-Error {
    param($Message)
    Write-Host "$Red❌ $Message$Reset"
}

# Check if cluster is running
Write-Status "Checking cluster status..." $Blue
try {
    $clusterInfo = kubectl cluster-info 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Cluster not accessible"
    }
    Write-Info "Cluster is accessible"
} catch {
    Write-Error "Kubernetes cluster is not running or accessible"
    Write-Info "Run: .\scripts\setup-cluster.ps1"
    exit 1
}

# Check if we have 3 nodes with proper labels
$nodes = kubectl get nodes --no-headers -o custom-columns=":metadata.name"
$nodeCount = ($nodes -split "`n" | Where-Object { $_.Trim() -ne "" }).Count

if ($nodeCount -ne 3) {
    Write-Error "Expected 3 nodes, found $nodeCount"
    Write-Info "Run: .\scripts\setup-cluster.ps1 -Clean"
    exit 1
}

# Verify node labels
Write-Info "Verifying node labels..."
$appNodes = kubectl get nodes -l type=application --no-headers
$dbNodes = kubectl get nodes -l type=database --no-headers  
$serviceNodes = kubectl get nodes -l type=dependent_services --no-headers

if (-not $appNodes -or -not $dbNodes -or -not $serviceNodes) {
    Write-Error "Nodes are not properly labeled"
    Write-Info "Run: .\scripts\setup-cluster.ps1"
    exit 1
}

Write-Info "Node architecture verified ✓"

# Build and load Docker image
if (-not $SkipBuild) {
    Write-Status "Building Docker image..." $Yellow
    docker build -t student-api:latest .
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to build Docker image"
        exit 1
    }
    
    Write-Info "Loading image into Minikube..."
    minikube image load student-api:latest
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to load image into Minikube"
        exit 1
    }
    Write-Info "Docker image loaded successfully ✓"
} else {
    Write-Warning "Skipping Docker build (using existing image)"
}

# Deploy based on namespace parameter
function Deploy-Namespace {
    param($NamespaceName, $ManifestPath, $Description)
    
    Write-Status "Deploying $Description..." $Green
    
    # Apply manifests
    kubectl apply -f $ManifestPath
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to deploy $Description"
        return $false
    }
    
    Write-Info "$Description deployed successfully ✓"
    return $true
}

function Wait-ForPods {
    param($Namespace, $Selector, $Description, $TimeoutSeconds = 300)
    
    Write-Info "Waiting for $Description to be ready..."
    kubectl wait --for=condition=Ready pods -l $Selector -n $Namespace --timeout="${TimeoutSeconds}s"
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "$Description pods not ready within $TimeoutSeconds seconds"
        return $false
    }
    Write-Info "$Description pods are ready ✓"
    return $true
}

# Deployment sequence
$deploymentSuccess = $true

if ($Namespace -eq "all" -or $Namespace -eq "secrets") {
    if (-not (Deploy-Namespace "secrets" "k8s/manifests/secrets/" "secrets")) {
        $deploymentSuccess = $false
    }
}

if ($Namespace -eq "all" -or $Namespace -eq "database") {
    if (-not (Deploy-Namespace "database" "k8s/manifests/database/" "database services")) {
        $deploymentSuccess = $false
    } else {
        # Wait for database to be ready before proceeding
        Wait-ForPods "database" "app=postgres" "PostgreSQL" 180
        Wait-ForPods "database" "app=redis" "Redis" 120
    }
}

if ($Namespace -eq "all" -or $Namespace -eq "monitoring") {
    if (-not (Deploy-Namespace "monitoring" "k8s/manifests/monitoring/" "monitoring services")) {
        $deploymentSuccess = $false
    } else {
        # Wait for monitoring to be ready
        Wait-ForPods "monitoring" "app=prometheus" "Prometheus" 120
        Wait-ForPods "monitoring" "app=grafana" "Grafana" 120
    }
}

if ($Namespace -eq "all" -or $Namespace -eq "applications") {
    if (-not (Deploy-Namespace "applications" "k8s/manifests/applications/" "application services")) {
        $deploymentSuccess = $false
    } else {
        # Wait for applications to be ready
        Wait-ForPods "applications" "app=student-api" "Student API" 180
        Wait-ForPods "applications" "app=nginx-lb" "NGINX Load Balancer" 120
    }
}

if (-not $deploymentSuccess) {
    Write-Error "Some deployments failed. Check the logs above."
    exit 1
}

# Verify deployment
Write-Status "Verifying deployment..." $Blue

Write-Info "Checking pod distribution across nodes..."
kubectl get pods -o wide --all-namespaces

Write-Host ""
Write-Info "Checking service endpoints..."
kubectl get services --all-namespaces

Write-Host ""
Write-Info "Checking ingress/NodePort access..."
$minikubeIP = minikube ip

Write-Host ""
Write-Status "Deployment complete! 🎉" $Green

Write-Host ""
Write-Info "Access Points:"
Write-Host "  🌐 API Load Balancer: http://localhost:31080"
Write-Host "  📊 Prometheus: http://localhost:31090" 
Write-Host "  📈 Grafana: http://localhost:31030 (admin/admin123)"
Write-Host "  🎛️  Kubernetes Dashboard: minikube dashboard"

Write-Host ""
Write-Info "Quick Tests:"
Write-Host "  # Test API health"
Write-Host "  curl http://localhost:31080/health"
Write-Host ""
Write-Host "  # Test API endpoints"  
Write-Host "  curl http://localhost:31080/api/v1/students"
Write-Host ""
Write-Host "  # Port forward for development"
Write-Host "  kubectl port-forward svc/nginx-lb 8080:8080 -n applications"

Write-Host ""
Write-Info "Monitoring:"
Write-Host "  # View all pods"
Write-Host "  kubectl get pods --all-namespaces -o wide"
Write-Host ""
Write-Host "  # View logs"
Write-Host "  kubectl logs -l app=student-api -n applications"
Write-Host ""
Write-Host "  # Scale API"
Write-Host "  kubectl scale deployment student-api --replicas=3 -n applications"

if ($Verbose) {
    Write-Host ""
    Write-Status "Detailed Status:" $Blue
    kubectl get all --all-namespaces
}
