# Targets to manage Docker services

# Build the Docker image for the API
build-api:
	@echo "Building the REST API Docker image..."
	docker build -t student-api:latest -f Dockerfile .

# ==============================================================================
# DEVELOPMENT TARGETS (existing functionality)
# ==============================================================================

# Run the REST API container (development)
run-api: build-api
	@echo "Starting the REST API container..."
	docker-compose up -d api

# Stop all running services
stop:
	@echo "Stopping all services..."
	docker-compose down

# Restart all services (useful for development)
restart: stop run-api

# Clean up resources (remove containers, volumes, etc.)
clean:
	@echo "Cleaning up..."
	docker-compose down --volumes --rmi all

# Health check for API
healthcheck:
	@echo "Checking the health of the API..."
	curl -f http://localhost:5000/api/v1/healthcheck || echo "Healthcheck failed"

# Run tests
test:
	@echo "Running tests..."
	pytest tests/

# Perform code linting
lint:
	@echo "Performing code linting..."
	flake8 .

# ==============================================================================
# PRODUCTION TARGETS (new bare metal functionality)
# ==============================================================================

# Build production images
build-prod:
	@echo "Building production images..."
	docker-compose -f production/docker-compose.prod.yaml build

# Deploy production environment
deploy-prod:
	@echo "Deploying production environment..."
	docker-compose -f production/docker-compose.prod.yaml up -d

# Stop production environment
stop-prod:
	@echo "Stopping production environment..."
	docker-compose -f production/docker-compose.prod.yaml down

# Restart production environment
restart-prod: stop-prod deploy-prod

# Clean up production environment
clean-prod:
	@echo "Cleaning up production environment..."
	docker-compose -f production/docker-compose.prod.yaml down --volumes --rmi all

# Production health check
healthcheck-prod:
	@echo "Checking production health..."
	@echo "Testing Nginx load balancer..."
	curl -f http://localhost:8080/health || echo "Nginx healthcheck failed"
	@echo "Testing API endpoints..."
	curl -f http://localhost:8080/api/v1/healthcheck || echo "API healthcheck failed"
	@echo "Testing student endpoints..."
	curl -f http://localhost:8080/api/v1/students || echo "Students endpoint failed"

# Show production logs
logs-prod:
	@echo "Showing production logs..."
	docker-compose -f production/docker-compose.prod.yaml logs -f

# ==============================================================================
# VAGRANT TARGETS (bare metal deployment)
# ==============================================================================

# Start Vagrant box
vagrant-up:
	@echo "Starting Vagrant box..."
	cd vagrant && vagrant up

# SSH into Vagrant box
vagrant-ssh:
	@echo "SSH into Vagrant box..."
	cd vagrant && vagrant ssh

# Destroy Vagrant box
vagrant-destroy:
	@echo "Destroying Vagrant box..."
	cd vagrant && vagrant destroy -f

# Reload Vagrant box
vagrant-reload:
	@echo "Reloading Vagrant box..."
	cd vagrant && vagrant reload

# Deploy to Vagrant (complete workflow)
vagrant-deploy: vagrant-up
	@echo "Deploying to Vagrant..."
	cd vagrant && vagrant ssh -c "cd /vagrant && make deploy-prod"

# ==============================================================================
# DATABASE MANAGEMENT (production)
# ==============================================================================

# Run database migrations in production
migrate-prod:
	@echo "Running database migrations in production..."
	docker-compose -f production/docker-compose.prod.yaml exec student-api-1 flask db upgrade

# Create new migration
create-migration:
	@echo "Creating new migration..."
	@set /p msg="Enter migration message: " && docker-compose -f production/docker-compose.prod.yaml exec student-api-1 flask db migrate -m "%msg%"

# Initialize database (first time setup)
init-db-prod:
	@echo "Initializing production database..."
	docker-compose -f production/docker-compose.prod.yaml exec student-api-1 flask db init
	docker-compose -f production/docker-compose.prod.yaml exec student-api-1 flask db migrate -m "Initial migration"
	docker-compose -f production/docker-compose.prod.yaml exec student-api-1 flask db upgrade

# ==============================================================================
# MONITORING AND DEBUGGING
# ==============================================================================

# Show production container status
ps-prod:
	@echo "Showing production container status..."
	docker-compose -f production/docker-compose.prod.yaml ps

# Show production container resource usage
top-prod:
	@echo "Showing production container resource usage..."
	docker-compose -f production/docker-compose.prod.yaml top

# Scale API containers
scale-api:
	@echo "Scaling API containers..."
	@if "%replicas%"=="" (echo Usage: make scale-api replicas=3 && exit /b 1)
	docker-compose -f production/docker-compose.prod.yaml up -d --scale student-api-1=%replicas% --scale student-api-2=%replicas%

# ==============================================================================
# TESTING AND VALIDATION
# ==============================================================================

# Test load balancing
test-load-balance:
	@echo "Testing load balancing..."
	@for /l %%i in (1,1,10) do (echo Request %%i: && curl -s http://localhost:8080/api/v1/healthcheck && timeout /t 1 /nobreak > nul)

# Comprehensive health check
health-check-all:
	@echo "Running comprehensive health check..."
	@echo "1. Checking Nginx..."
	@curl -f http://localhost:8080/health && echo "✅ Nginx OK" || echo "❌ Nginx Failed"
	@echo "2. Checking API health..."
	@curl -f http://localhost:8080/api/v1/healthcheck && echo "✅ API Health OK" || echo "❌ API Health Failed"
	@echo "3. Checking database connection..."
	@curl -f http://localhost:8080/api/v1/students && echo "✅ Database OK" || echo "❌ Database Failed"
	@echo "4. Checking container status..."
	@docker-compose -f production/docker-compose.prod.yaml ps

# ==============================================================================
# HELP
# ==============================================================================

help:
	@echo "Available targets:"
	@echo ""
	@echo "Development:"
	@echo "  build-api        - Build the API Docker image"
	@echo "  run-api          - Start development environment"
	@echo "  stop             - Stop development environment"
	@echo "  restart          - Restart development environment"
	@echo "  clean            - Clean up development environment"
	@echo "  healthcheck      - Check development API health"
	@echo "  test             - Run tests"
	@echo "  lint             - Run code linting"
	@echo ""
	@echo "Production:"
	@echo "  build-prod       - Build production images"
	@echo "  deploy-prod      - Deploy production environment"
	@echo "  stop-prod        - Stop production environment"
	@echo "  restart-prod     - Restart production environment"
	@echo "  clean-prod       - Clean up production environment"
	@echo "  healthcheck-prod - Check production health"
	@echo "  logs-prod        - Show production logs"
	@echo ""
	@echo "Vagrant (Bare Metal):"
	@echo "  vagrant-up       - Start Vagrant box"
	@echo "  vagrant-ssh      - SSH into Vagrant box"
	@echo "  vagrant-destroy  - Destroy Vagrant box"
	@echo "  vagrant-deploy   - Deploy to Vagrant"
	@echo ""
	@echo "Database:"
	@echo "  migrate-prod     - Run database migrations"
	@echo "  create-migration - Create new migration"
	@echo "  init-db-prod     - Initialize production database"
	@echo ""
	@echo "Monitoring:"
	@echo "  ps-prod          - Show container status"
	@echo "  top-prod         - Show resource usage"
	@echo "  scale-api        - Scale API containers (use: make scale-api replicas=3)"
	@echo "  test-load-balance - Test load balancing"
	@echo "  health-check-all - Comprehensive health check"