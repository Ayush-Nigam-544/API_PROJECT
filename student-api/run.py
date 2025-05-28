#!/usr/bin/env python3
"""
Main application entry point for the Student API.
This file is used to run the Flask application.
"""

import os
from app import create_app

# Create the Flask application
app = create_app()

if __name__ == '__main__':
    # Get configuration from environment variables
    host = os.environ.get('API_HOST', '0.0.0.0')
    port = int(os.environ.get('API_PORT', 5000))
    debug = os.environ.get('FLASK_ENV') == 'development'
    
    print(f"🚀 Starting Student API on {host}:{port}")
    print(f"🔧 Environment: {os.environ.get('FLASK_ENV', 'development')}")
    print(f"🗄️ Database: {app.config.get('SQLALCHEMY_DATABASE_URI', 'Not configured')}")
    
    app.run(host=host, port=port, debug=debug)
