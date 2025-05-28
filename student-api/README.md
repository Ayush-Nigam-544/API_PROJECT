Student REST API - Production Ready with Monitoring
===================================================

A production-ready RESTful API for managing student records with comprehensive monitoring, caching, and high availability features.

## 🚀 Features

### Core API Features
- **CRUD operations** for student management
- **Flask + SQLAlchemy ORM** with PostgreSQL/SQLite support
- **Database migrations** with Alembic
- **Input validation** and error handling
- **JSON logging** for production monitoring

### Production Features
- **Load balancing** with NGINX (2 API instances)
- **Redis caching** with smart invalidation (5-minute TTL)
- **High availability** with health checks
- **Prometheus metrics** collection
- **Grafana dashboards** for monitoring
- **Comprehensive monitoring** stack (11 containers)
- **Database connection pooling**
- **Graceful error handling** and fallback mechanisms

### Monitoring & Observability
- **Prometheus metrics**: Request counts, response times, error rates
- **Grafana dashboards**: Real-time performance visualization
- **System metrics**: CPU, memory, disk usage
- **Database metrics**: Connection counts, query performance
- **Cache metrics**: Hit/miss ratios, memory usage
- **Health checks**: Application and infrastructure monitoring

## 📁 Project Structure
```
student-api/
├── app/                          # Flask application
│   ├── __init__.py              # App factory with Redis & Prometheus
│   ├── config.py                # Environment configurations
│   ├── models.py                # SQLAlchemy models
│   ├── routes.py                # API endpoints with caching
│   └── tests/                   # Test suite
├── production/                   # Production deployment
│   ├── docker-compose.monitoring.yaml  # Complete monitoring stack
│   ├── docker-compose.prod.yaml       # Production API stack
│   └── init.sql                       # Database initialization
├── monitoring/                   # Monitoring configurations
│   ├── prometheus.yml           # Metrics collection config
│   ├── alert_rules.yml          # Alert definitions
│   └── grafana/                 # Dashboard configurations
├── nginx/                       # Load balancer
│   ├── nginx.conf              # Load balancer configuration
│   └── Dockerfile              # NGINX container
└── Makefile                     # Deployment & management commands
```

## 🛠️ Prerequisites

### System Requirements
- **Windows 10/11** (PowerShell 5.1 or later)
- **Docker Desktop** 4.0+ with WSL2 enabled
- **Docker Compose** v2.0+ (included with Docker Desktop)
- **Git** for version control
- **4GB+ RAM** (8GB recommended for monitoring stack)
- **10GB+ free disk space**

### Required Software Installation

#### 1. Install Docker Desktop
```powershell
# Download from: https://www.docker.com/products/docker-desktop/
# Or install via Chocolatey:
choco install docker-desktop
```

#### 2. Verify Docker Installation
```powershell
docker --version          # Should show Docker version 20.0+
docker-compose --version  # Should show Docker Compose version 2.0+
docker info               # Should show Docker is running
```

#### 3. Configure Docker (Important!)
```powershell
# Increase Docker memory allocation to at least 4GB
# Docker Desktop → Settings → Resources → Advanced → Memory: 4GB+
# Enable WSL2 integration if on Windows
```

## 🚀 Quick Start Guide

### Option 1: Complete Production Stack (Recommended)
```powershell
# 1. Clone and navigate to project
git clone <repository-url>
cd student-api

# 2. Deploy complete monitoring stack (11 containers)
make deploy-prod

# 3. Wait for all services to start (2-3 minutes)
# Monitor deployment progress:
make logs-prod

# 4. Verify all services are healthy
make health-check-all
```

### Option 2: Simple API Development
```powershell
# 1. Build and run basic API
make build-api
make run-api

# 2. Test basic functionality
make healthcheck
```

## 📊 Production Stack Components

When you run `make deploy-prod`, the following services are deployed:

| Service | Port | Purpose | Health Check |
|---------|------|---------|--------------|
| **NGINX Load Balancer** | 8080 | API Gateway & Load Balancing | http://localhost:8080/health |
| **Flask API Instance 1** | 5000 | Primary API Application | Internal health checks |
| **Flask API Instance 2** | 5000 | Secondary API Application | Internal health checks |
| **PostgreSQL Database** | 5432 | Primary Data Storage | Connection tests |
| **Redis Cache** | 6379 | Performance Caching | Redis ping tests |
| **Prometheus** | 9090 | Metrics Collection | http://localhost:9090 |
| **Grafana** | 3000 | Monitoring Dashboards | http://localhost:3000 |
| **Node Exporter** | 9100 | System Metrics | http://localhost:9100/metrics |
| **PostgreSQL Exporter** | 9187 | Database Metrics | http://localhost:9187/metrics |
| **Redis Exporter** | 9121 | Cache Metrics | http://localhost:9121/metrics |

## 🧪 Testing & Validation Commands

### 1. Health Check Commands
```powershell
# Comprehensive health check of all services
make health-check-all

# Individual service health checks
curl http://localhost:8080/health                    # NGINX Load Balancer
curl http://localhost:8080/api/v1/healthcheck       # API Health (via load balancer)
curl http://localhost:9090/-/healthy                # Prometheus
curl http://localhost:3000/api/health               # Grafana

# Container status check
docker-compose -f production/docker-compose.monitoring.yaml ps
```

### 2. API Endpoint Testing
```powershell
# Get all students (tests database + caching)
curl http://localhost:8080/api/v1/students

# Get specific student (tests caching)
curl http://localhost:8080/api/v1/students/1

# Create new student (tests database writes + cache invalidation)
curl -X POST http://localhost:8080/api/v1/students `
  -H "Content-Type: application/json" `
  -d '{"name": "Test Student", "email": "test@example.com", "age": 20}'

# Update student (tests cache invalidation)
curl -X PUT http://localhost:8080/api/v1/students/1 `
  -H "Content-Type: application/json" `
  -d '{"name": "Updated Name", "age": 21}'

# Delete student (tests cache invalidation)
curl -X DELETE http://localhost:8080/api/v1/students/1

# Test Redis cache statistics
curl http://localhost:8080/api/v1/cache/stats

# Test readiness probe
curl http://localhost:8080/api/v1/ready
```

### 3. Load Balancing Testing
```powershell
# Test load balancing between API instances
for ($i=1; $i -le 10; $i++) {
    Write-Host "Request $i:"
    curl -s http://localhost:8080/api/v1/healthcheck
    Start-Sleep -Seconds 1
}

# Advanced load testing
make test-load-balance
```

### 4. Monitoring & Metrics Testing
```powershell
# Test Prometheus metrics collection
curl http://localhost:9090/api/v1/query?query=up

# Test custom application metrics
curl http://localhost:8080/api/v1/metrics

# Test system metrics
curl http://localhost:9100/metrics

# Test database metrics
curl http://localhost:9187/metrics

# Test Redis metrics
curl http://localhost:9121/metrics
```

### 5. Cache Performance Testing
```powershell
# Test cache hit (should be fast after first request)
Measure-Command { curl http://localhost:8080/api/v1/students }

# Test cache miss (after clearing cache)
# This will be slower as it hits the database
curl -X POST http://localhost:8080/api/v1/students `
  -H "Content-Type: application/json" `
  -d '{"name": "Cache Test", "email": "cache@test.com"}'

# Check cache statistics
curl http://localhost:8080/api/v1/cache/stats
```

## 🖥️ Monitoring Dashboards

### Prometheus (Metrics Collection)
- **URL**: http://localhost:9090
- **Purpose**: Raw metrics collection and querying
- **Key Queries**:
  ```
  rate(flask_http_requests_total[5m])          # Request rate
  flask_http_request_duration_seconds          # Response time
  redis_connected_clients                      # Redis connections
  postgres_stat_database_numbackends          # DB connections
  ```

### Grafana (Visualization)
- **URL**: http://localhost:3000
- **Login**: admin / admin123
- **Purpose**: Visual dashboards and alerting
- **Pre-configured**: Student API performance dashboard

## 🛠️ Management Commands

### Production Management
```powershell
# Deploy production stack
make deploy-prod              # Start all 11 containers

# Monitor and maintain
make logs-prod               # View all container logs
make ps-prod                 # Show container status
make top-prod                # Show resource usage

# Restart and cleanup
make restart-prod            # Restart all services
make stop-prod               # Stop all services
make clean-prod              # Remove all containers and data
```

### Development Commands
```powershell
# Basic development
make build-api               # Build API Docker image
make run-api                 # Start development API
make stop                    # Stop development services
make test                    # Run test suite
make lint                    # Code quality checks
```

### Database Management
```powershell
# Production database operations
make migrate-prod            # Run database migrations
make init-db-prod            # Initialize database (first time)
make create-migration        # Create new migration

# Development database
make reset-db                # Reset development database
```

### Scaling and Performance
```powershell
# Scale API instances
make scale-api replicas=5    # Scale to 5 API instances

# Performance testing
make test-load-balance       # Test load balancer
make health-check-all        # Comprehensive health check
```

## 🔧 Environment Configuration

### Production Environment Variables
```bash
# Database
DATABASE_URL=postgresql://student_user:student_password@db:5432/students
REDIS_URL=redis://redis:6379/0

# Application
FLASK_ENV=production
FLASK_APP=app
API_HOST=0.0.0.0
API_PORT=5000

# Monitoring
PROMETHEUS_PORT=9090
GRAFANA_PORT=3000
```

### Development Environment Variables
```bash
# Database (SQLite for development)
DATABASE_URL=sqlite:///students.db
FLASK_ENV=development
SECRET_KEY=dev-secret-key
```

## 🚨 Troubleshooting Guide

### Common Issues and Solutions

#### 1. Docker Issues
```powershell
# Check Docker status
docker info

# Restart Docker Desktop
# Docker Desktop → Restart

# Clean Docker system
docker system prune -a --volumes
```

#### 2. Port Conflicts
```powershell
# Check what's using ports
netstat -aon | findstr :8080
netstat -aon | findstr :9090
netstat -aon | findstr :3000

# Kill processes if needed
taskkill /PID <PID> /F
```

#### 3. Container Health Issues
```powershell
# Check container logs
docker logs student-api-1
docker logs student-prometheus
docker logs student-grafana

# Restart specific service
docker-compose -f production/docker-compose.monitoring.yaml restart prometheus
```

#### 4. Memory Issues
```powershell
# Check Docker memory usage
docker stats

# Increase Docker memory limit
# Docker Desktop → Settings → Resources → Memory: 8GB+
```

#### 5. Network Issues
```powershell
# Recreate Docker network
docker-compose -f production/docker-compose.monitoring.yaml down
docker network prune
make deploy-prod
```

### Performance Optimization

#### 1. Redis Cache Optimization
```powershell
# Monitor cache performance
curl http://localhost:8080/api/v1/cache/stats

# Expected good metrics:
# - hit_ratio > 0.8 (80%+ cache hits)
# - used_memory < 100MB for normal load
```

#### 2. Database Optimization
```powershell
# Monitor database connections
curl http://localhost:9187/metrics | Select-String "postgres_stat_database_numbackends"

# Expected: < 10 connections per API instance
```

#### 3. API Performance
```powershell
# Monitor response times
curl http://localhost:9090/api/v1/query?query=rate(flask_http_request_duration_seconds_sum[5m])

# Expected: < 200ms average response time
```

## 📊 Monitoring Best Practices

### Key Metrics to Monitor
- **Request Rate**: `rate(flask_http_requests_total[5m])`
- **Error Rate**: `rate(flask_http_requests_total{status=~"5.."}[5m])`
- **Response Time**: `histogram_quantile(0.95, rate(flask_http_request_duration_seconds_bucket[5m]))`
- **Cache Hit Ratio**: `redis_keyspace_hits / (redis_keyspace_hits + redis_keyspace_misses)`
- **Database Connections**: `postgres_stat_database_numbackends`

### Alert Thresholds
- **API Down**: `up{job="student-api"} == 0`
- **High Error Rate**: `rate(flask_http_requests_total{status=~"5.."}[5m]) > 0.1`
- **High Response Time**: `histogram_quantile(0.95, rate(flask_http_request_duration_seconds_bucket[5m])) > 2`
- **Low Cache Hit Rate**: `redis_keyspace_hits / (redis_keyspace_hits + redis_keyspace_misses) < 0.8`

## 🎯 Production Deployment Checklist

### Before Deployment
- [ ] Docker Desktop installed and running
- [ ] At least 4GB RAM allocated to Docker
- [ ] Ports 8080, 9090, 3000 available
- [ ] Windows PowerShell 5.1+ available

### Initial Deployment
- [ ] `make deploy-prod` completed successfully
- [ ] All 11 containers showing as healthy
- [ ] `make health-check-all` passes
- [ ] Prometheus accessible at http://localhost:9090
- [ ] Grafana accessible at http://localhost:3000

### Post-Deployment Testing
- [ ] API endpoints responding correctly
- [ ] Load balancer distributing traffic
- [ ] Redis caching working (check cache stats)
- [ ] Database queries executing
- [ ] Metrics being collected
- [ ] Dashboards showing data

### Ongoing Monitoring
- [ ] Set up Grafana alerts
- [ ] Monitor system resource usage
- [ ] Regular health checks
- [ ] Performance baseline established
- [ ] Backup strategy implemented

## 📚 API Documentation

### Student Management Endpoints

| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| GET | `/api/v1/students` | Get all students | None | Array of student objects |
| GET | `/api/v1/students/{id}` | Get specific student | None | Student object |
| POST | `/api/v1/students` | Create new student | `{"name": "string", "email": "string", "age": number}` | Created student object |
| PUT | `/api/v1/students/{id}` | Update student | `{"name": "string", "email": "string", "age": number}` | Updated student object |
| DELETE | `/api/v1/students/{id}` | Delete student | None | Success message |

### Monitoring Endpoints

| Method | Endpoint | Description | Response |
|--------|----------|-------------|----------|
| GET | `/api/v1/healthcheck` | API health status | Health status object |
| GET | `/api/v1/ready` | Readiness probe | Readiness status |
| GET | `/api/v1/metrics` | Prometheus metrics | Metrics in Prometheus format |
| GET | `/api/v1/cache/stats` | Redis cache statistics | Cache performance metrics |
| GET | `/health` | NGINX health | Load balancer status |

## 🔒 Security Considerations

### Production Security
- Database credentials are configured via environment variables
- API runs as non-root user in containers
- NGINX provides reverse proxy protection
- Internal services are not exposed to host network
- Health check endpoints have minimal information exposure

### Development Security
- Default credentials are for development only
- SQLite database for local development
- Debug mode disabled in production
- Structured logging for audit trails

Author
------
Ayush Nigam