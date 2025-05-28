import logging
from pythonjsonlogger import jsonlogger
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
import os
import redis
from prometheus_client import generate_latest, Counter, Histogram, Gauge
import time

# Initialize the database and migration
db = SQLAlchemy()
migrate = Migrate()

# Initialize Redis connection
redis_client = None

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_LATENCY = Histogram('http_request_duration_seconds', 'HTTP request latency')
ACTIVE_CONNECTIONS = Gauge('active_connections', 'Active database connections')

# Function to set up logger
def setup_logger():
    logger = logging.getLogger(__name__)
    log_handler = logging.StreamHandler()

    # Define the JSON log format
    formatter = jsonlogger.JsonFormatter('%(asctime)s %(levelname)s %(name)s %(message)s')
    log_handler.setFormatter(formatter)
    logger.addHandler(log_handler)
    logger.setLevel(logging.INFO)
    return logger

# Initialize logger inside create_app() to avoid potential import issues
def create_app(config_name=None):
    app = Flask(__name__)
    
    global redis_client

    # Determine configuration
    if config_name is None:
        config_name = os.environ.get('FLASK_ENV', 'development')
    
    # Import and apply configuration
    from app.config import config
    app.config.from_object(config.get(config_name, config['default']))
    
    # Ensure we also load from the config.py file for backward compatibility
    try:
        app.config.from_pyfile('config.py')
    except FileNotFoundError:
        pass  # config.py might not exist, that's ok
    
    # Initialize Redis
    try:
        redis_url = os.environ.get('REDIS_URL', 'redis://localhost:6379/0')
        redis_client = redis.from_url(redis_url, decode_responses=True)
        redis_client.ping()  # Test connection
        app.logger.info(f"Redis connected successfully: {redis_url}")
    except Exception as e:
        app.logger.warning(f"Redis connection failed: {e}. Continuing without Redis.")
        redis_client = None
    
    # Add Redis to app context
    app.redis = redis_client
    
    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)

    # Set up the logger
    logger = setup_logger()
    
    # Register blueprints
    from app.routes import api_bp
    app.register_blueprint(api_bp)
    
    # Add metrics endpoint
    @app.route('/metrics')
    def metrics():
        return generate_latest()

    # Attach logger to the app so it's accessible globally
    app.logger = logger

    return app
