# Targets to manage Docker services

# Check if the SQLite database exists
# Check if the SQLite database exists
check-db:
    @echo "Checking if the SQLite database exists..."
    @if [ ! -f "./instance/students.db" ]; then echo "Database does not exist. Please create the database first."; exit 1; else echo "Database exists."; fi
# Build the Docker image for the API
build-api:
	@echo "Building the REST API Docker image..."
	docker-compose build api

# Run the REST API container
run-api: check-db build-api
	@echo "Starting the REST API container..."
	docker-compose up -d api  # Start the API service

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