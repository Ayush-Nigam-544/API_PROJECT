import logging
from pythonjsonlogger import jsonlogger
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
import os

# Initialize the database and migration
db = SQLAlchemy()
migrate = Migrate()

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
def create_app():
    app = Flask(__name__)

    # Configuration
    app.config.from_pyfile('config.py')
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    
    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)

    # Set up the logger
    logger = setup_logger()
    
    # Register blueprints
    from app.routes import api_bp
    app.register_blueprint(api_bp)

    # Attach logger to the app so it's accessible globally
    app.logger = logger

    return app
