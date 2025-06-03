#!/usr/bin/env pwsh
# Kubernetes Cluster Setup Script
# This script sets up a 3-node Minikube cluster with proper node labeling

param(
    [switch]$Clean = $false,
    [switch]$Verbose = $false
)

# Colors for output
$Green = "`e[32m"
$Yellow = "`e[33m"
$Red = "`e[31m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-Status {
    param($Message, $Color = $Green)
    Write-Host "$Color[INFO] $Message$Reset"
}

function Write-Info {
    param($Message)
    Write-Host "$Blue[INFO] $Message$Reset"
}

function Write-Warning {
    param($Message)
    Write-Host "$Yellow[WARN] $Message$Reset"
}

function Write-Error {
    param($Message)
    Write-Host "$Red[ERROR] $Message$Reset"
}

# Check prerequisites
Write-Status "Checking prerequisites..." $Blue

# Check if Minikube is installed
try {
    $minikubeVersion = minikube version --short 2>$null
    Write-Info "Minikube version: $minikubeVersion"
} catch {
    Write-Error "Minikube is not installed. Please install Minikube first."
    Write-Info "Install via: choco install minikube"
    exit 1
}

# Check if kubectl is installed
try {
    $kubectlVersion = kubectl version --client --short 2>$null
    Write-Info "kubectl version: $kubectlVersion"
} catch {
    Write-Error "kubectl is not installed. Please install kubectl first."
    Write-Info "Install via: choco install kubernetes-cli"
    exit 1
}

# Check if Docker is running
try {
    docker info >$null 2>&1
    Write-Info "Docker is running"
} catch {
    Write-Error "Docker is not running. Please start Docker Desktop."
    exit 1
}

# Clean up existing cluster if requested
if ($Clean) {
    Write-Status "Cleaning up existing cluster..." $Yellow
    minikube delete 2>$null
    Start-Sleep -Seconds 5
}

# Check if cluster already exists
$clusterStatus = minikube status 2>$null
if ($clusterStatus -match "Running") {
    Write-Info "Minikube cluster already running. Checking node count..."
    $nodes = kubectl get nodes --no-headers 2>$null
    $nodeCount = ($nodes | Measure-Object).Count
    
    if ($nodeCount -eq 3) {
        Write-Warning "3-node cluster already exists. Use -Clean to recreate."
        $choice = Read-Host "Do you want to continue with existing cluster? (y/N)"
        if ($choice -ne "y" -and $choice -ne "Y") {
            Write-Info "Exiting without changes."
            exit 0
        }
    } else {
        Write-Warning "Existing cluster has $nodeCount nodes. Need 3 nodes."
        minikube delete
        Start-Sleep -Seconds 5
    }
}

# Start Minikube cluster with 3 nodes
Write-Status "Starting 3-node Minikube cluster..." $Green
Write-Info "This may take 3-5 minutes..."

try {
    # Start cluster with specific resources
    minikube start --nodes 3 --cpus 2 --memory 2048 --driver docker --kubernetes-version=v1.28.0
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to start Minikube cluster"
    }
} catch {
    Write-Error "Failed to start Minikube cluster: $_"
    Write-Info "Try: minikube delete && docker system prune"
    exit 1
}

# Wait for nodes to be ready
Write-Status "Waiting for nodes to be ready..." $Yellow
kubectl wait --for=condition=Ready nodes --all --timeout=300s
if ($LASTEXITCODE -ne 0) {
    Write-Error "Nodes failed to become ready within 5 minutes"
    exit 1
}

# Get node names
Write-Status "Getting node information..." $Blue
$nodes = kubectl get nodes --no-headers -o custom-columns=":metadata.name"
$nodeArray = $nodes -split "`n" | Where-Object { $_.Trim() -ne "" }

if ($nodeArray.Count -ne 3) {
    Write-Error "Expected 3 nodes, found $($nodeArray.Count)"
    Write-Info "Nodes found: $($nodeArray -join ', ')"
    exit 1
}

Write-Info "Found nodes: $($nodeArray -join ', ')"

# Label nodes according to our architecture
Write-Status "Labeling nodes for specialized workloads..." $Green

# Node A: Applications (main node)
Write-Info "Labeling $($nodeArray[0]) as application node..."
kubectl label nodes $nodeArray[0] type=application tier=app --overwrite
kubectl label nodes $nodeArray[0] workload=api --overwrite

# Node B: Database (second node)
Write-Info "Labeling $($nodeArray[1]) as database node..."
kubectl label nodes $nodeArray[1] type=database tier=data --overwrite
kubectl label nodes $nodeArray[1] workload=storage --overwrite

# Node C: Dependent Services (third node)
Write-Info "Labeling $($nodeArray[2]) as dependent services node..."
kubectl label nodes $nodeArray[2] type=dependent_services tier=services --overwrite
kubectl label nodes $nodeArray[2] workload=monitoring --overwrite

# Verify labels
Write-Status "Verifying node labels..." $Blue
kubectl get nodes --show-labels

# Create namespaces
Write-Status "Creating namespaces..." $Green
kubectl apply -f k8s/manifests/namespaces.yaml
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create namespaces"
    exit 1
}

# Verify namespaces
Write-Info "Verifying namespaces..."
kubectl get namespaces

# Enable necessary addons
Write-Status "Enabling Minikube addons..." $Yellow
minikube addons enable metrics-server
minikube addons enable dashboard

# Display cluster information
Write-Status "Cluster setup complete! Success!" $Green
Write-Host ""
Write-Info "Cluster Information:"
kubectl cluster-info

Write-Host ""
Write-Info "Node Architecture:"
Write-Host "  [APP] Node A ($($nodeArray[0])): Application services (API, NGINX)"
Write-Host "  [DB]  Node B ($($nodeArray[1])): Database services (PostgreSQL, Redis)"
Write-Host "  [MON] Node C ($($nodeArray[2])): Monitoring services (Prometheus, Grafana)"

Write-Host ""
Write-Info "Access Points (after deployment):"
Write-Host "  [WEB] API Load Balancer: http://localhost:31080"
Write-Host "  [MON] Prometheus: http://localhost:31090"
Write-Host "  [VIZ] Grafana: http://localhost:31030"
Write-Host "  [UI]  Kubernetes Dashboard: minikube dashboard"

Write-Host ""
Write-Status "Next steps:" $Blue
Write-Host "  1. Deploy applications: .\scripts\deploy-all.ps1"
Write-Host "  2. Check status: kubectl get pods --all-namespaces"
Write-Host "  3. View dashboard: minikube dashboard"

if ($Verbose) {
    Write-Host ""
    Write-Info "Detailed node information:"
    kubectl describe nodes
}
