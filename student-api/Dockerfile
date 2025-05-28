# ---- Build Stage ----
FROM python:3.9-slim as builder

WORKDIR /app

# Install build dependencies for PostgreSQL and other packages
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    libpq-dev \
    curl && \
  rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# ---- Runtime Stage ----
FROM python:3.9-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    libpq5 \
    curl && \
  rm -rf /var/lib/apt/lists/*

# Copy virtual env from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application files
COPY app ./app
COPY migrations ./migrations
COPY run.py .
COPY .env .env

# Create instance directory for SQLite (development)
RUN mkdir -p instance

# Runtime configuration
ENV FLASK_APP=run.py
ENV FLASK_ENV=development
ENV PYTHONPATH=/app
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:5000/api/v1/healthcheck || exit 1

# Run as non-root user
RUN useradd -m api_user && \
    chown -R api_user:api_user /app
USER api_user

# Use Python directly instead of flask command for better control
CMD ["python", "run.py"]