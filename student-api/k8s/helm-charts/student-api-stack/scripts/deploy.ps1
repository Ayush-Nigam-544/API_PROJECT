# Student API Helm Deployment Script
# Deploy, upgrade, or manage the Student API Helm stack

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("install", "upgrade", "uninstall", "status", "logs", "test")]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("prod", "test")]
    [string]$Environment = "test",
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "student-api-helm",
    
    [Parameter(Mandatory=$false)]
    [string]$ReleaseName = "student-api-helm",
    
    [Parameter(Mandatory=$false)]
    [string]$HelmPath = "C:\tools\helm\helm.exe"
)

Write-Host "🚀 Student API Helm Deployment Manager" -ForegroundColor Green
Write-Host "Action: $Action | Environment: $Environment | Namespace: $Namespace" -ForegroundColor Cyan

# Set values file based on environment
$ValuesFile = if ($Environment -eq "prod") { "values.yaml" } else { "values-test.yaml" }
Write-Host "Using values file: $ValuesFile" -ForegroundColor Yellow

switch ($Action) {
    "install" {
        Write-Host "📦 Installing Helm release..." -ForegroundColor Blue
        & $HelmPath install $ReleaseName . -n $Namespace --create-namespace -f $ValuesFile
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Installation completed successfully!" -ForegroundColor Green
            Write-Host "🔗 Setting up port forwarding..." -ForegroundColor Blue
            Start-Process powershell -ArgumentList "-NoExit", "-Command", "kubectl port-forward service/$ReleaseName-student-api-stack-nginx 8080:80 -n $Namespace"
            Write-Host "🌐 API will be available at: http://localhost:8080" -ForegroundColor Green
        } else {
            Write-Host "❌ Installation failed!" -ForegroundColor Red
        }
    }
    
    "upgrade" {
        Write-Host "🔄 Upgrading Helm release..." -ForegroundColor Blue
        & $HelmPath upgrade $ReleaseName . -n $Namespace -f $ValuesFile
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Upgrade completed successfully!" -ForegroundColor Green
        } else {
            Write-Host "❌ Upgrade failed!" -ForegroundColor Red
        }
    }
    
    "uninstall" {
        Write-Host "🗑️ Uninstalling Helm release..." -ForegroundColor Red
        $confirmation = Read-Host "Are you sure you want to uninstall $ReleaseName? (y/N)"
        if ($confirmation -eq "y" -or $confirmation -eq "Y") {
            & $HelmPath uninstall $ReleaseName -n $Namespace
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Uninstallation completed!" -ForegroundColor Green
            } else {
                Write-Host "❌ Uninstallation failed!" -ForegroundColor Red
            }
        } else {
            Write-Host "⏸️ Uninstallation cancelled." -ForegroundColor Yellow
        }
    }
    
    "status" {
        Write-Host "📊 Checking deployment status..." -ForegroundColor Blue
        Write-Host "`n🏷️ Helm Release Status:" -ForegroundColor Cyan
        & $HelmPath status $ReleaseName -n $Namespace
        
        Write-Host "`n🐳 Pod Status:" -ForegroundColor Cyan
        kubectl get pods -n $Namespace
        
        Write-Host "`n🌐 Service Status:" -ForegroundColor Cyan
        kubectl get services -n $Namespace
        
        Write-Host "`n🔍 Quick Health Check:" -ForegroundColor Cyan
        $healthyPods = (kubectl get pods -n $Namespace --no-headers | Where-Object { $_ -match "Running.*1/1" }).Count
        $totalPods = (kubectl get pods -n $Namespace --no-headers).Count
        Write-Host "Healthy Pods: $healthyPods/$totalPods" -ForegroundColor $(if ($healthyPods -eq $totalPods) { "Green" } else { "Yellow" })
    }
    
    "logs" {
        Write-Host "📋 Fetching application logs..." -ForegroundColor Blue
        $apiPod = kubectl get pods -n $Namespace -l app.kubernetes.io/component=api --no-headers | Select-Object -First 1 | ForEach-Object { ($_ -split '\s+')[0] }
        if ($apiPod) {
            Write-Host "Showing logs for pod: $apiPod" -ForegroundColor Cyan
            kubectl logs $apiPod -n $Namespace --tail=50 --follow
        } else {
            Write-Host "❌ No API pods found!" -ForegroundColor Red
        }
    }
    
    "test" {
        Write-Host "🧪 Running deployment tests..." -ForegroundColor Blue
        
        # Check if port forwarding is active
        $portForwardActive = Get-Process -Name "kubectl" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -like "*port-forward*" }
        
        if (-not $portForwardActive) {
            Write-Host "🔗 Starting port forwarding..." -ForegroundColor Yellow
            Start-Process powershell -ArgumentList "-WindowStyle", "Hidden", "-Command", "kubectl port-forward service/$ReleaseName-student-api-stack-nginx 8080:80 -n $Namespace"
            Start-Sleep -Seconds 3
        }
        
        # Test health check endpoint
        try {
            Write-Host "🏥 Testing health check endpoint..." -ForegroundColor Cyan
            $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/healthcheck" -TimeoutSec 10
            Write-Host "✅ Health check: $($healthResponse.status)" -ForegroundColor Green
        } catch {
            Write-Host "❌ Health check failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        # Test students endpoint
        try {
            Write-Host "👥 Testing students endpoint..." -ForegroundColor Cyan
            $studentsResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/students" -TimeoutSec 10
            Write-Host "✅ Students endpoint: Retrieved $($studentsResponse.Count) students" -ForegroundColor Green
        } catch {
            Write-Host "❌ Students endpoint failed: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host "`n🌐 API is available at: http://localhost:8080" -ForegroundColor Green
        Write-Host "📖 Available endpoints:" -ForegroundColor Cyan
        Write-Host "  - GET  /api/v1/healthcheck  (Health check)" -ForegroundColor White
        Write-Host "  - GET  /api/v1/ready        (Readiness check)" -ForegroundColor White
        Write-Host "  - GET  /api/v1/students     (List students)" -ForegroundColor White
        Write-Host "  - POST /api/v1/students     (Create student)" -ForegroundColor White
        Write-Host "  - GET  /api/v1/students/:id (Get student)" -ForegroundColor White
        Write-Host "  - PUT  /api/v1/students/:id (Update student)" -ForegroundColor White
        Write-Host "  - DELETE /api/v1/students/:id (Delete student)" -ForegroundColor White
    }
}

Write-Host "`n🏁 Operation completed!" -ForegroundColor Green
