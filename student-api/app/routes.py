from flask import Blueprint, request, jsonify, current_app
from app.models import Student
from app import db
from werkzeug.exceptions import BadRequest

api_bp = Blueprint('api', __name__, url_prefix='/api/v1')

# POST: Create a new student
@api_bp.route('/students', methods=['POST'])
def create_student():
    try:
        data = request.get_json()
        
        # Validation
        if not data or 'email' not in data or 'name' not in data:
            current_app.logger.warning("Invalid student data", extra={"data": data})
            raise BadRequest("Name and email are required")
            
        current_app.logger.info("Creating student", extra={"email": data['email']})
        
        student = Student(
            name=data['name'],
            email=data['email'],
            age=data.get('age'),
            grade=data.get('grade')
        )
        
        db.session.add(student)
        db.session.commit()
        
        current_app.logger.info(f"Student created", extra={"student_id": student.id})
        return jsonify(student.to_dict()), 201
        
    except BadRequest as e:
        current_app.logger.error("Bad Request: Student creation failed", exc_info=True)
        return jsonify({"error": str(e)}), 400  # Returning the BadRequest error with 400 status
        
    except Exception as e:
        current_app.logger.error("Student creation failed", exc_info=True)
        return jsonify({"error": "Internal Server Error"}), 500

# GET: Retrieve all students
@api_bp.route('/students', methods=['GET'])
def get_students():
    try:
        current_app.logger.info("Fetching students")
        students = Student.query.all()
        return jsonify([student.to_dict() for student in students]), 200
    except Exception as e:
        current_app.logger.error("Failed to fetch students", exc_info=True)
        return jsonify({"error": "Failed to fetch students"}), 500

# Healthcheck endpoint
@api_bp.route('/healthcheck', methods=['GET'])
def healthcheck():
    """Healthcheck endpoint to ensure the API is alive and well"""
    return jsonify({"status": "healthy"}), 200
