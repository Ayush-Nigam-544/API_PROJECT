import os

class Config:
    """Base configuration class."""
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'

class DevelopmentConfig(Config):
    """Development configuration."""
    DEBUG = True
    # SQLite for development
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'sqlite:///students.db'

class ProductionConfig(Config):
    """Production configuration."""
    DEBUG = False
    # PostgreSQL for production
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or \
        'postgresql://student_user:student_password@localhost:5432/students'

class TestingConfig(Config):
    """Testing configuration."""
    TESTING = True
    # In-memory SQLite for testing
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'

# Configuration dictionary
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}

# Legacy variables for backward compatibility
SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or 'sqlite:///students.db' 
SQLALCHEMY_TRACK_MODIFICATIONS = False

