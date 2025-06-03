# Student API Helm Rollback Script
# Rollback to previous Helm chart revisions

param(
    [Parameter(Mandatory=$false)]
    [int]$Revision = 0,
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = "student-api-helm",
    
    [Parameter(Mandatory=$false)]
    [string]$ReleaseName = "student-api-helm",
    
    [Parameter(Mandatory=$false)]
    [string]$HelmPath = "C:\tools\helm\helm.exe"
)

Write-Host "🔄 Student API Helm Rollback Manager" -ForegroundColor Green
Write-Host "Release: $ReleaseName | Namespace: $Namespace" -ForegroundColor Cyan

# Get release history
Write-Host "`n📜 Release History:" -ForegroundColor Blue
& $HelmPath history $ReleaseName -n $Namespace

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to get release history!" -ForegroundColor Red
    exit 1
}

# If no revision specified, show options
if ($Revision -eq 0) {
    Write-Host "`n🤔 No revision specified. Available options:" -ForegroundColor Yellow
    Write-Host "  - Use -Revision N to rollback to specific revision" -ForegroundColor White
    Write-Host "  - Use -Revision -1 to rollback to previous revision" -ForegroundColor White
    
    $userChoice = Read-Host "`nEnter revision number to rollback to (or 'q' to quit)"
    
    if ($userChoice -eq "q" -or $userChoice -eq "Q") {
        Write-Host "⏸️ Rollback cancelled." -ForegroundColor Yellow
        exit 0
    }
    
    try {
        $Revision = [int]$userChoice
    } catch {
        Write-Host "❌ Invalid revision number!" -ForegroundColor Red
        exit 1
    }
}

# Confirm rollback
Write-Host "`n⚠️ WARNING: This will rollback the release to revision $Revision" -ForegroundColor Yellow
$confirmation = Read-Host "Are you sure you want to proceed? (y/N)"

if ($confirmation -ne "y" -and $confirmation -ne "Y") {
    Write-Host "⏸️ Rollback cancelled." -ForegroundColor Yellow
    exit 0
}

# Perform rollback
Write-Host "`n🔄 Rolling back to revision $Revision..." -ForegroundColor Blue

if ($Revision -eq -1) {
    # Rollback to previous revision
    & $HelmPath rollback $ReleaseName -n $Namespace
} else {
    # Rollback to specific revision
    & $HelmPath rollback $ReleaseName $Revision -n $Namespace
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Rollback completed successfully!" -ForegroundColor Green
    
    # Show updated status
    Write-Host "`n📊 Post-rollback Status:" -ForegroundColor Cyan
    & $HelmPath status $ReleaseName -n $Namespace
    
    Write-Host "`n🐳 Pod Status:" -ForegroundColor Cyan
    kubectl get pods -n $Namespace
    
    Write-Host "`n🔗 Setting up port forwarding..." -ForegroundColor Blue
    Start-Process powershell -ArgumentList "-WindowStyle", "Hidden", "-Command", "kubectl port-forward service/$ReleaseName-student-api-stack-nginx 8080:80 -n $Namespace"
    
    Write-Host "🌐 API will be available at: http://localhost:8080" -ForegroundColor Green
    Write-Host "🧪 Run '.\scripts\deploy.ps1 -Action test' to verify the rollback" -ForegroundColor Yellow
    
} else {
    Write-Host "❌ Rollback failed!" -ForegroundColor Red
    Write-Host "💡 Check the Helm history and try again with a valid revision" -ForegroundColor Yellow
}

Write-Host "`n🏁 Rollback operation completed!" -ForegroundColor Green
