Student REST API
===============

A RESTful API for managing student records, built with Flask, SQLAlchemy, Alembic, and Docker. Supports both SQLite (default) and PostgreSQL, and is ready for local development or containerized deployment.

Features
--------
- CRUD operations for students
- Flask + SQLAlchemy ORM
- Alembic migrations for database schema management
- Pytest-based test suite
- Dockerized for easy deployment
- Makefile for common developer tasks
- Ready-to-use PowerShell script for Windows dependency setup

Project Structure
----------------
app/
  __init__.py
  models.py
  routes.py
migrations/
  versions/
tests/
  test_app.py
Dockerfile
Makefile
requirements.txt

Quick Start
----------

1. Clone the Repository:
git clone <repository-url>
cd <project-directory>

2. Install Dependencies (Windows):
.\setup.ps1
OR
make install

3. Build and Run with Docker:
make build-api    # Build the Docker image
make run-api      # Start the API container (http://localhost:5000)

4. Running Tests:
make test        # Run all tests

5. Code Linting:
make lint        # Run flake8 linting

6. Database Migrations:
make init-db     # Initialize database and migrations
make migrate     # Create new migration
make upgrade     # Apply migrations

7. Health Check:
make healthcheck  # Verify API is running

Environment Variables
--------------------
DATABASE_URL (default: sqlite:///students.db)
FLASK_ENV (default: development)

Set variables in .env file or directly:
export DATABASE_URL=postgresql://user:password@localhost:5432/studentdb

Makefile Command Reference
-------------------------

Docker Management:
make build-api    # Build Docker image
make run-api      # Run API container
make stop         # Stop all containers
make restart      # Restart services
make clean        # Remove all containers and images

Development:
make install      # Install Python dependencies
make shell        # Open Flask shell
make routes       # Show all API routes

Database:
make init-db      # Initialize database
make migrate      # Generate new migration
make upgrade      # Apply migrations
make downgrade    # Rollback last migration

Testing & Quality:
make test         # Run all tests
make test-coverage # Run tests with coverage report
make lint         # Run flake8 linting
make format       # Format code with black

Utility:
make healthcheck  # Check API status
make logs         # View container logs

Development Notes
----------------

Local Database:
Default SQLite location: instance/students.db
make reset-db     # WARNING: Drops and recreates database

Switch to PostgreSQL:
1. Update .env:
   DATABASE_URL=postgresql://user:password@localhost:5432/studentdb
2. Rebuild containers:
make clean build-api run-api

Troubleshooting
--------------

Common Issues:

Docker not starting:
make docker-check  # Verify Docker installation

Database connection issues:
make db-check      # Test database connection

Missing dependencies:
make install       # Reinstall requirements

Author
------
Ayush Nigam