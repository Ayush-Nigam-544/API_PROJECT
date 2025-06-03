# Kubernetes Deployment Guide 🚀

This directory contains all the necessary Kubernetes manifests and scripts to deploy the Student API application on a 3-node Minikube cluster with specialized node roles.

## 🏗️ Architecture Overview

### Node Specialization
- **Node A (Application)**: `type=application` - Runs API services and load balancer
- **Node B (Database)**: `type=database` - Runs PostgreSQL and Redis
- **Node C (Services)**: `type=dependent_services` - Runs monitoring stack

### Service Distribution
```
┌─────────────────┬─────────────────┬─────────────────┐
│   Node A (App)  │  Node B (Data)  │ Node C (Monitor)│
├─────────────────┼─────────────────┼─────────────────┤
│ Student API x2  │ PostgreSQL      │ Prometheus      │
│ NGINX LB        │ Redis           │ Grafana         │
│                 │                 │                 │
└─────────────────┴─────────────────┴─────────────────┘
```

## 📁 Directory Structure

```
k8s/
├── manifests/
│   ├── namespaces.yaml              # Namespace definitions
│   ├── applications/                # Node A manifests
│   │   ├── student-api-deployment.yaml
│   │   ├── nginx-deployment.yaml
│   │   └── nginx-configmap.yaml
│   ├── database/                    # Node B manifests
│   │   ├── postgres-statefulset.yaml
│   │   ├── postgres-service.yaml
│   │   └── redis-deployment.yaml
│   ├── monitoring/                  # Node C manifests
│   │   ├── prometheus-deployment.yaml
│   │   ├── prometheus-config.yaml
│   │   ├── grafana-deployment.yaml
│   │   └── grafana-config.yaml
│   └── secrets/
│       └── database-secrets.yaml
├── scripts/
│   ├── setup-cluster.ps1           # Cluster initialization
│   ├── deploy-all.ps1              # Application deployment
│   └── cleanup.ps1                 # Resource cleanup
└── README-k8s.md                   # This file
```

## 🔧 Prerequisites

### System Requirements
- **Windows 10/11** with PowerShell 5.1+
- **Docker Desktop** 4.0+ with WSL2 enabled
- **Minikube** v1.30+
- **kubectl** v1.28+
- **8GB+ RAM** (minimum 4GB allocated to Docker)
- **20GB+ free disk space**

### Installation Commands
```powershell
# Install via Chocolatey
choco install minikube kubernetes-cli kubernetes-helm

# Or install manually
# Minikube: https://minikube.sigs.k8s.io/docs/start/
# kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
```

## 🚀 Quick Start

### 1. Initial Setup
```powershell
# Navigate to project root
cd c:\Users\ayush_ihx9hgx\vsc_workspace\API_PROJECT\student-api

# Setup 3-node cluster with labels
.\k8s\scripts\setup-cluster.ps1

# Build and deploy applications
.\k8s\scripts\deploy-all.ps1
```

### 2. Verify Deployment
```powershell
# Check cluster status
kubectl get nodes --show-labels

# Check pod distribution
kubectl get pods -o wide --all-namespaces

# Test API
curl http://localhost:31080/api/v1/students
```

## 📊 Service Endpoints

### External Access (NodePort)
| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| **API Load Balancer** | 31080 | http://localhost:31080 | Main application access |
| **Prometheus** | 31090 | http://localhost:31090 | Metrics collection |
| **Grafana** | 31030 | http://localhost:31030 | Monitoring dashboards |

### Internal Services (ClusterIP)
| Service | FQDN | Port | Purpose |
|---------|------|------|---------|
| **Student API** | `student-api.applications.svc.cluster.local` | 5000 | API backend |
| **PostgreSQL** | `postgres.database.svc.cluster.local` | 5432 | Database |
| **Redis** | `redis.database.svc.cluster.local` | 6379 | Cache |

## 🛠️ Management Commands

### Cluster Management
```powershell
# Setup new cluster
.\k8s\scripts\setup-cluster.ps1

# Clean setup (delete existing cluster)
.\k8s\scripts\setup-cluster.ps1 -Clean

# View cluster info
minikube status
kubectl cluster-info
```

### Application Deployment
```powershell
# Deploy all services
.\k8s\scripts\deploy-all.ps1

# Deploy specific namespace
.\k8s\scripts\deploy-all.ps1 -Namespace applications

# Skip Docker build (use existing image)
.\k8s\scripts\deploy-all.ps1 -SkipBuild

# Verbose deployment
.\k8s\scripts\deploy-all.ps1 -Verbose
```

### Resource Cleanup
```powershell
# Interactive cleanup
.\k8s\scripts\cleanup.ps1

# Clean specific namespace
.\k8s\scripts\cleanup.ps1 -Namespace applications

# Clean everything without prompts
.\k8s\scripts\cleanup.ps1 -All -Force

# Destroy entire cluster
.\k8s\scripts\cleanup.ps1 -Cluster -Force
```

## 🧪 Testing & Validation

### Health Checks
```powershell
# Test all endpoints
curl http://localhost:31080/health                    # NGINX health
curl http://localhost:31080/api/v1/healthcheck       # API health
curl http://localhost:31090/-/healthy                # Prometheus
curl http://localhost:31030/api/health               # Grafana

# Check pod health
kubectl get pods --all-namespaces
kubectl describe pods -n applications
```

### API Testing
```powershell
# Get all students
curl http://localhost:31080/api/v1/students

# Create student
curl -X POST http://localhost:31080/api/v1/students `
  -H "Content-Type: application/json" `
  -d '{"name": "K8s Student", "email": "k8s@test.com", "age": 22}'

# Test caching
curl http://localhost:31080/api/v1/cache/stats

# Test metrics
curl http://localhost:31080/api/v1/metrics
```

### Load Balancing Test
```powershell
# Test multiple requests to see load balancing
for ($i=1; $i -le 10; $i++) {
    Write-Host "Request $i:"
    curl -s http://localhost:31080/api/v1/healthcheck | ConvertFrom-Json
    Start-Sleep -Seconds 1
}
```

### Node Placement Verification
```powershell
# Verify pods are on correct nodes
kubectl get pods -o wide --all-namespaces

# Should show:
# - student-api, nginx-lb on application node
# - postgres, redis on database node  
# - prometheus, grafana on services node
```

## 📈 Monitoring & Observability

### Prometheus Metrics
- **URL**: http://localhost:31090
- **Key Queries**:
  ```promql
  rate(flask_http_requests_total[5m])          # Request rate
  flask_http_request_duration_seconds          # Response time
  up{job="student-api"}                        # Service uptime
  ```

### Grafana Dashboards
- **URL**: http://localhost:31030
- **Login**: admin / admin123
- **Features**: Pre-configured Student API dashboard

### Kubernetes Dashboard
```powershell
# Open Kubernetes dashboard
minikube dashboard

# View metrics
kubectl top nodes
kubectl top pods --all-namespaces
```

## 🔄 Scaling Operations

### Scale API Instances
```powershell
# Scale to 3 replicas
kubectl scale deployment student-api --replicas=3 -n applications

# Auto-scale based on CPU
kubectl autoscale deployment student-api --cpu-percent=50 --min=2 --max=5 -n applications

# Check scaling status
kubectl get hpa -n applications
```

### Resource Management
```powershell
# View resource usage
kubectl top pods --all-namespaces
kubectl describe nodes

# Edit resource limits
kubectl edit deployment student-api -n applications
```

## 🔧 Troubleshooting

### Common Issues

#### Pods Stuck in Pending
```powershell
# Check node resources
kubectl describe nodes

# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Solution: Increase node resources or clean up
minikube config set memory 4096
minikube config set cpus 4
```

#### Image Pull Errors
```powershell
# Rebuild and reload image
docker build -t student-api:latest .
minikube image load student-api:latest

# Verify image is loaded
minikube image ls | findstr student-api
```

#### Service Not Accessible
```powershell
# Check service endpoints
kubectl get svc --all-namespaces
kubectl get endpoints --all-namespaces

# Port forward for debugging
kubectl port-forward svc/nginx-lb 8080:8080 -n applications
```

#### Database Connection Issues
```powershell
# Check database pod logs
kubectl logs -l app=postgres -n database

# Test database connectivity
kubectl exec -it <postgres-pod> -n database -- psql -U student_user -d students -c "\dt"
```

### Debug Commands
```powershell
# View all resources
kubectl get all --all-namespaces

# Check pod logs
kubectl logs -l app=student-api -n applications --tail=50

# Interactive debugging
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash

# Network debugging
kubectl run debug --image=busybox -it --rm -- /bin/sh
```

## 📋 Environment Comparison

### Docker Compose vs Kubernetes

| Aspect | Docker Compose | Kubernetes |
|--------|----------------|------------|
| **Endpoints** | localhost:8080, :9090, :3000 | localhost:31080, :31090, :31030 |
| **Deployment** | `make deploy-prod` | `.\k8s\scripts\deploy-all.ps1` |
| **Scaling** | `docker-compose up --scale` | `kubectl scale deployment` |
| **Monitoring** | Direct container access | K8s dashboard + existing tools |
| **Networking** | Docker networks | K8s services + namespaces |
| **Storage** | Docker volumes | PVCs + StatefulSets |

### When to Use Each

**Docker Compose** (localhost:8080):
- ✅ Development and testing
- ✅ Quick prototyping
- ✅ Production simulation
- ✅ Simpler resource management

**Kubernetes** (localhost:31080):
- ✅ Learning container orchestration
- ✅ Production-like environment
- ✅ Advanced scaling scenarios
- ✅ Multi-node deployment patterns

## 🎯 Production Readiness

### Security Considerations
- Secrets managed via Kubernetes secrets
- RBAC controls (can be added)
- Network policies (can be implemented)
- Pod security policies

### High Availability Features
- Multi-replica deployments
- Health checks and probes
- Automatic pod restart
- Load balancing across replicas

### Monitoring Stack
- Prometheus metrics collection
- Grafana visualization
- Custom application metrics
- Kubernetes cluster metrics

---

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
- [Helm Charts](https://helm.sh/docs/)

---

**Author**: Ayush Nigam  
**Branch**: k8s  
**Last Updated**: May 28, 2025
