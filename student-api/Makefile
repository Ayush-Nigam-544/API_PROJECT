# Targets to manage Docker services

# Check if the SQLite database exists
check-db: build-api
	@echo "Checking if the SQLite database exists inside the container..."
	docker run --rm -v ${PWD}/instance:/app/instance student-api:latest powershell -Command "Write-Host 'Checking path:' (Resolve-Path './instance/students.db'); if (-Not (Test-Path './instance/students.db')) { Write-Host 'Database does not exist. Please create the database first.'; exit 1 } else { Write-Host 'Database exists.' }"

# Build the Docker image for the API
build-api:
	@echo "Building the REST API Docker image..."
	docker build -t student-api:latest -f Dockerfile .

# Run the REST API container
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