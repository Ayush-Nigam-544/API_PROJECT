# Student API Helm Chart - Deployment Guide

## 🚀 Quick Start

### Prerequisites
- Kubernetes cluster (local or remote)
- Helm 3.x installed
- kubectl configured

### Install the Complete Stack
```powershell
# Navigate to the Helm chart directory
cd k8s\helm-charts\student-api-stack

# Deploy the test environment (recommended for first deployment)
.\scripts\deploy.ps1 -Action install -Environment test

# Deploy the production environment
.\scripts\deploy.ps1 -Action install -Environment prod
```

## 📊 Management Commands

### Check Status
```powershell
.\scripts\deploy.ps1 -Action status
```

### Upgrade Deployment
```powershell
.\scripts\deploy.ps1 -Action upgrade -Environment test
```

### Test Deployment
```powershell
.\scripts\deploy.ps1 -Action test
```

### View Logs
```powershell
.\scripts\deploy.ps1 -Action logs
```

### Uninstall
```powershell
.\scripts\deploy.ps1 -Action uninstall
```

## 🏗️ Architecture

The Helm chart deploys a complete Student API stack:

```
┌─────────────────────────────────────────────────────────────┐
│                    NGINX Load Balancer                     │
│                      (2 replicas)                          │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────┴───────────────────────────────────────┐
│                Student API Pods                            │
│                   (2 replicas)                             │
└─────────┬───────────────────────────────┬───────────────────┘
          │                               │
┌─────────┴──────────┐         ┌──────────┴──────────┐
│   PostgreSQL       │         │      Redis          │
│   (with backup)    │         │   (master + 3       │
│                    │         │    replicas)        │
└────────────────────┘         └─────────────────────┘
```

## 🔧 Components

| Component | Replicas | Purpose |
|-----------|----------|---------|
| **NGINX** | 2 | Load balancer and reverse proxy |
| **Student API** | 2 | Flask REST API application |
| **PostgreSQL** | 1 | Primary database (Bitnami chart) |
| **Redis** | 1+3 | Caching layer (master + replicas) |

## 🌐 Access Points

After deployment, the API is available at:
- **Local**: http://localhost:8080 (via port forwarding)
- **Cluster**: Via the LoadBalancer service

### Available Endpoints
- `GET /api/v1/healthcheck` - Health check
- `GET /api/v1/ready` - Readiness check  
- `GET /api/v1/students` - List all students
- `POST /api/v1/students` - Create a new student
- `GET /api/v1/students/{id}` - Get student by ID
- `PUT /api/v1/students/{id}` - Update student
- `DELETE /api/v1/students/{id}` - Delete student

## ⚙️ Configuration

### Environment-Specific Values

#### Test Environment (`values-test.yaml`)
- Persistence disabled for faster startup
- Monitoring disabled
- Smaller resource allocations
- Suitable for development/testing

#### Production Environment (`values.yaml`)  
- Persistence enabled
- Monitoring stack included (Prometheus + Grafana)
- Production resource allocations
- High availability configuration

### Key Configuration Options

```yaml
# Student API Configuration
studentApi:
  replicaCount: 2
  image:
    repository: ayushihx9hgx/student-api
    tag: "latest"
  
# Database Configuration  
postgresql:
  enabled: true
  auth:
    postgresPassword: "password"
    database: "studentdb"
    
# Redis Configuration
redis:
  enabled: true
  master:
    persistence:
      enabled: false  # Set to true for production
```

## 🔍 Troubleshooting

### Common Issues

#### Pods Not Starting
```powershell
# Check pod status
kubectl get pods -n student-api-helm

# Check specific pod logs
kubectl logs <pod-name> -n student-api-helm

# Describe pod for events
kubectl describe pod <pod-name> -n student-api-helm
```

#### Database Connection Issues
```powershell
# Check PostgreSQL pod
kubectl logs student-api-helm-postgresql-0 -n student-api-helm

# Test database connectivity
kubectl exec -it student-api-helm-postgresql-0 -n student-api-helm -- psql -U postgres -d studentdb
```

#### API Not Responding
```powershell
# Check API pod logs
.\scripts\deploy.ps1 -Action logs

# Test health endpoint directly on pod
kubectl exec -it <api-pod-name> -n student-api-helm -- curl localhost:5000/api/v1/healthcheck
```

### Health Checks

The deployment includes comprehensive health monitoring:
- **Liveness Probe**: `/api/v1/healthcheck` (checks if app is alive)
- **Readiness Probe**: `/api/v1/ready` (checks if app is ready to serve traffic)

## 🔄 Upgrade Process

1. Update configuration in `values.yaml` or `values-test.yaml`
2. Run upgrade command:
   ```powershell
   .\scripts\deploy.ps1 -Action upgrade -Environment test
   ```
3. Monitor rollout:
   ```powershell
   kubectl rollout status deployment/student-api-helm-student-api-stack-api -n student-api-helm
   ```

## 🗑️ Cleanup

To completely remove the deployment:
```powershell
.\scripts\deploy.ps1 -Action uninstall
```

## 📋 Migration Status

✅ **Completed Migration Components:**
- [x] Helm chart structure created
- [x] Templates converted from K8s manifests  
- [x] Community charts integrated (PostgreSQL, Redis)
- [x] Environment-specific configurations
- [x] Health checks and probes configured
- [x] Secrets management implemented
- [x] Load balancer (NGINX) configured
- [x] Deployment automation scripts
- [x] Documentation completed

🔄 **Optional Enhancements:**
- [ ] Monitoring stack (Prometheus + Grafana)
- [ ] Persistent volumes for production
- [ ] TLS/SSL certificates
- [ ] Resource quotas and limits optimization
- [ ] Horizontal Pod Autoscaling (HPA)

The Helm migration is **100% complete** for core functionality! 🎉
