#!/usr/bin/env pwsh
# Kubernetes Cleanup Script
# This script cleans up Kubernetes resources and optionally destroys the cluster

param(
    [switch]$All = $false,
    [switch]$Cluster = $false,
    [string]$Namespace = "all",
    [switch]$Force = $false
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

function Confirm-Action {
    param($Message)
    if ($Force) {
        return $true
    }
    $choice = Read-Host "$Message (y/N)"
    return ($choice -eq "y" -or $choice -eq "Y")
}

# Check if cluster is accessible
try {
    kubectl cluster-info >$null 2>&1
    $clusterRunning = $true
} catch {
    $clusterRunning = $false
    Write-Warning "Kubernetes cluster is not accessible"
}

if ($clusterRunning) {
    Write-Status "Kubernetes cluster is accessible" $Blue
    
    # Show current resources
    Write-Info "Current resources in cluster:"
    kubectl get all --all-namespaces
    Write-Host ""
    
    if ($All -or $Namespace -eq "all") {
        if (Confirm-Action "Delete ALL application resources?") {
            Write-Status "Deleting all application resources..." $Yellow
            
            # Delete in reverse order of dependencies
            kubectl delete -f k8s/manifests/applications/ --ignore-not-found=true
            kubectl delete -f k8s/manifests/monitoring/ --ignore-not-found=true  
            kubectl delete -f k8s/manifests/database/ --ignore-not-found=true
            kubectl delete -f k8s/manifests/secrets/ --ignore-not-found=true
            
            # Delete namespaces (this will cascade delete all resources)
            kubectl delete namespace applications --ignore-not-found=true
            kubectl delete namespace database --ignore-not-found=true
            kubectl delete namespace monitoring --ignore-not-found=true
            
            Write-Info "All application resources deleted ✓"
        }
    } else {
        # Delete specific namespace
        if (Confirm-Action "Delete resources in namespace '$Namespace'?") {
            Write-Status "Deleting resources in namespace '$Namespace'..." $Yellow
            
            switch ($Namespace) {
                "applications" {
                    kubectl delete -f k8s/manifests/applications/ --ignore-not-found=true
                    kubectl delete namespace applications --ignore-not-found=true
                }
                "database" {
                    kubectl delete -f k8s/manifests/database/ --ignore-not-found=true
                    kubectl delete namespace database --ignore-not-found=true
                }
                "monitoring" {
                    kubectl delete -f k8s/manifests/monitoring/ --ignore-not-found=true
                    kubectl delete namespace monitoring --ignore-not-found=true
                }
                "secrets" {
                    kubectl delete -f k8s/manifests/secrets/ --ignore-not-found=true
                }
                default {
                    Write-Error "Unknown namespace: $Namespace"
                    Write-Info "Valid namespaces: applications, database, monitoring, secrets, all"
                    exit 1
                }
            }
            
            Write-Info "Resources in namespace '$Namespace' deleted ✓"
        }
    }
    
    # Clean up persistent volumes
    if ($All) {
        if (Confirm-Action "Delete persistent volumes and claims?") {
            Write-Status "Cleaning up persistent storage..." $Yellow
            kubectl delete pvc --all --all-namespaces --ignore-not-found=true
            kubectl delete pv --all --ignore-not-found=true
            Write-Info "Persistent storage cleaned up ✓"
        }
    }
}

# Destroy cluster if requested
if ($Cluster -or $All) {
    if (Confirm-Action "DESTROY the entire Minikube cluster?") {
        Write-Status "Destroying Minikube cluster..." $Red
        minikube delete
        if ($LASTEXITCODE -eq 0) {
            Write-Info "Minikube cluster destroyed ✓"
        } else {
            Write-Error "Failed to destroy Minikube cluster"
        }
    }
}

# Clean up Docker images if requested
if ($All) {
    if (Confirm-Action "Clean up Docker images?") {
        Write-Status "Cleaning up Docker images..." $Yellow
        
        # Remove our application image
        docker rmi student-api:latest 2>$null
        
        # Clean up Minikube cache
        minikube image rm student-api:latest 2>$null
        
        # Optional: Clean up unused Docker resources
        if (Confirm-Action "Run docker system prune (remove unused images, containers, networks)?") {
            docker system prune -f
            Write-Info "Docker system cleaned up ✓"
        }
    }
}

Write-Host ""
Write-Status "Cleanup complete! 🧹" $Green

# Show remaining resources if cluster still exists
try {
    kubectl cluster-info >$null 2>&1
    Write-Host ""
    Write-Info "Remaining resources:"
    kubectl get all --all-namespaces
    
    Write-Host ""
    Write-Info "Remaining namespaces:"
    kubectl get namespaces
} catch {
    Write-Info "No Kubernetes cluster running"
}

Write-Host ""
Write-Info "Available cleanup options:"
Write-Host "  .\scripts\cleanup.ps1                    # Interactive cleanup"
Write-Host "  .\scripts\cleanup.ps1 -Namespace apps    # Clean specific namespace"
Write-Host "  .\scripts\cleanup.ps1 -All -Force        # Clean everything without prompts"
Write-Host "  .\scripts\cleanup.ps1 -Cluster -Force    # Destroy cluster without prompts"
