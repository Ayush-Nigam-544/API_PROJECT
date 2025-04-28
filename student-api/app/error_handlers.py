from flask import Blueprint, jsonify
from werkzeug.exceptions import HTTPException

errors_bp = Blueprint('errors', __name__)

@errors_bp.app_errorhandler(400)
def bad_request(error):
    return jsonify({
        "error": "bad_request",
        "message": str(error.description)
    }), 400

@errors_bp.app_errorhandler(404)
def not_found(error):
    return jsonify({
        "error": "not_found",
        "message": "The requested resource was not found"
    }), 404

# Add more error handlers as needed...