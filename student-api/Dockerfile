# ---- Build Stage ----
FROM python:3.9-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && \
  apt-get install -y --no-install-recommends gcc python3-dev

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ---- Runtime Stage ----
FROM python:3.9-slim

WORKDIR /app

# Copy virtual env from builder
COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy application
COPY app ./app
COPY migrations ./migrations
COPY .env .env
# Default environment variables
COPY Makefile .

# Runtime configuration
ENV FLASK_APP=app
ENV FLASK_ENV=development
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:5000/api/v1/healthcheck || exit 1

# Run as non-root user
RUN useradd -m api_user && chown -R api_user:api_user /app
USER api_user

ENTRYPOINT ["flask", "run", "--host=0.0.0.0"]