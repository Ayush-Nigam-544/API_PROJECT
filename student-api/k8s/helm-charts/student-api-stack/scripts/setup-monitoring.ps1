# Student API Monitoring Setup Script
# Install Prometheus, Grafana, and monitoring components

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("install", "uninstall", "status")]
    [string]$Action = "install",
    
    [Parameter(Mandatory=$false)]
    [string]$MonitoringNamespace = "monitoring",
    
    [Parameter(Mandatory=$false)]
    [string]$HelmPath = "C:\tools\helm\helm.exe"
)

Write-Host "📊 Student API Monitoring Setup" -ForegroundColor Green
Write-Host "Action: $Action | Namespace: $MonitoringNamespace" -ForegroundColor Cyan

switch ($Action) {
    "install" {
        Write-Host "`n🔧 Installing monitoring stack..." -ForegroundColor Blue
        
        # Install Prometheus CRDs first
        Write-Host "📦 Installing Prometheus CRDs..." -ForegroundColor Yellow
        kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
        kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
        kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
        
        # Create monitoring namespace
        kubectl create namespace $MonitoringNamespace --dry-run=client -o yaml | kubectl apply -f -
        
        # Install Prometheus
        Write-Host "📊 Installing Prometheus..." -ForegroundColor Yellow
        & $HelmPath install prometheus prometheus-community/kube-prometheus-stack -n $MonitoringNamespace --set grafana.enabled=true --set alertmanager.enabled=true
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Monitoring stack installed successfully!" -ForegroundColor Green
            
            Write-Host "`n🔗 Access Information:" -ForegroundColor Cyan
            Write-Host "  Prometheus: kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n $MonitoringNamespace" -ForegroundColor White
            Write-Host "  Grafana: kubectl port-forward svc/prometheus-grafana 3000:80 -n $MonitoringNamespace" -ForegroundColor White
            Write-Host "  AlertManager: kubectl port-forward svc/prometheus-kube-prometheus-alertmanager 9093:9093 -n $MonitoringNamespace" -ForegroundColor White
            
            Write-Host "`n🔑 Grafana Login:" -ForegroundColor Cyan
            Write-Host "  Username: admin" -ForegroundColor White
            Write-Host "  Password: Run 'kubectl get secret prometheus-grafana -n $MonitoringNamespace -o jsonpath=`"{.data.admin-password}`" | base64 -d'" -ForegroundColor White
        } else {
            Write-Host "❌ Installation failed!" -ForegroundColor Red
        }
    }
    
    "uninstall" {
        Write-Host "`n🗑️ Uninstalling monitoring stack..." -ForegroundColor Red
        $confirmation = Read-Host "Are you sure you want to uninstall the monitoring stack? (y/N)"
        
        if ($confirmation -eq "y" -or $confirmation -eq "Y") {
            & $HelmPath uninstall prometheus -n $MonitoringNamespace
            kubectl delete namespace $MonitoringNamespace
            Write-Host "✅ Monitoring stack uninstalled!" -ForegroundColor Green
        } else {
            Write-Host "⏸️ Uninstall cancelled." -ForegroundColor Yellow
        }
    }
    
    "status" {
        Write-Host "`n📊 Monitoring Stack Status:" -ForegroundColor Blue
        & $HelmPath status prometheus -n $MonitoringNamespace
        
        Write-Host "`n🐳 Monitoring Pods:" -ForegroundColor Cyan
        kubectl get pods -n $MonitoringNamespace
        
        Write-Host "`n🌐 Services:" -ForegroundColor Cyan
        kubectl get services -n $MonitoringNamespace
    }
}

Write-Host "`n💡 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Configure ServiceMonitors for Student API" -ForegroundColor White
Write-Host "  2. Import Grafana dashboards for Flask applications" -ForegroundColor White
Write-Host "  3. Set up alerting rules for critical metrics" -ForegroundColor White
Write-Host "  4. Configure log aggregation with Loki" -ForegroundColor White

Write-Host "`n🏁 Monitoring setup completed!" -ForegroundColor Green
