from flask import Blueprint, request, jsonify, current_app, Response
from app.models import Student
from app import db
from werkzeug.exceptions import BadRequest
import json
import time
import threading
from prometheus_client import Counter, Histogram

api_bp = Blueprint('api', __name__, url_prefix='/api/v1')

# Prometheus metrics
REQUEST_COUNT = Counter('api_requests_total', 'Total API requests', ['method', 'endpoint', 'status'])
REQUEST_LATENCY = Histogram('api_request_duration_seconds', 'API request latency', ['endpoint'])

# Simple metrics storage (in production, use proper metrics library like prometheus_client)
metrics = {
    'http_requests_total': 0,
    'http_request_duration_seconds': [],
    'active_connections': 0,
    'database_connections': 0
}
metrics_lock = threading.Lock()

def record_request_metrics(start_time, status_code):
    """Record request metrics"""
    duration = time.time() - start_time
    with metrics_lock:
        metrics['http_requests_total'] += 1
        metrics['http_request_duration_seconds'].append(duration)
        # Keep only last 1000 requests
        if len(metrics['http_request_duration_seconds']) > 1000:
            metrics['http_request_duration_seconds'].pop(0)

def before_request():
    """Before request handler"""
    request.start_time = time.time()
    with metrics_lock:
        metrics['active_connections'] += 1

def after_request(response):
    """After request handler"""
    if hasattr(request, 'start_time'):
        record_request_metrics(request.start_time, response.status_code)
    with metrics_lock:
        metrics['active_connections'] = max(0, metrics['active_connections'] - 1)
    return response

# Register request handlers
api_bp.before_request(before_request)
api_bp.after_request(after_request)

# Cache helper functions
def get_from_cache(key):
    """Get data from Redis cache"""
    if current_app.redis:
        try:
            data = current_app.redis.get(key)
            if data:
                return json.loads(data)
        except Exception as e:
            current_app.logger.warning(f"Cache get failed: {e}")
    return None

def set_cache(key, data, timeout=300):
    """Set data in Redis cache with timeout (default 5 minutes)"""
    if current_app.redis:
        try:
            current_app.redis.setex(key, timeout, json.dumps(data, default=str))
        except Exception as e:
            current_app.logger.warning(f"Cache set failed: {e}")

def delete_cache_pattern(pattern):
    """Delete cache keys matching pattern"""
    if current_app.redis:
        try:
            keys = current_app.redis.keys(pattern)
            if keys:
                current_app.redis.delete(*keys)
        except Exception as e:
            current_app.logger.warning(f"Cache delete failed: {e}")

# POST: Create a new student
@api_bp.route('/students', methods=['POST'])
def create_student():
    start_time = time.time()
    try:
        data = request.get_json()
        
        # Validation
        if not data or 'email' not in data or 'name' not in data:
            current_app.logger.warning("Invalid student data", extra={"data": data})
            REQUEST_COUNT.labels(method='POST', endpoint='/students', status='400').inc()
            raise BadRequest("Name and email are required")
    
        current_app.logger.info("Creating student", extra={"email": data['email']})
        student = Student(
            name=data['name'],
            email=data['email'],
            age=data.get('age')
        )
        
        db.session.add(student)
        db.session.commit()
        
        # Clear cache for students list
        delete_cache_pattern('students:*')
        
        current_app.logger.info(f"Student created", extra={"student_id": student.id})
        REQUEST_COUNT.labels(method='POST', endpoint='/students', status='201').inc()
        return jsonify(student.to_dict()), 201
        
    except BadRequest as e:
        REQUEST_COUNT.labels(method='POST', endpoint='/students', status='400').inc()
        current_app.logger.error("Bad Request: Student creation failed", exc_info=True)
        return jsonify({"error": str(e)}), 400
        
    except Exception as e:
        REQUEST_COUNT.labels(method='POST', endpoint='/students', status='500').inc()
        current_app.logger.error("Student creation failed", exc_info=True)
        return jsonify({"error": "Internal Server Error"}), 500
    finally:
        REQUEST_LATENCY.labels(endpoint='/students').observe(time.time() - start_time)

# GET: Retrieve all students
@api_bp.route('/students', methods=['GET'])
def get_students():
    start_time = time.time()
    try:
        current_app.logger.info("Fetching students")
        
        # Try to get from cache first
        cache_key = "students:all"
        cached_students = get_from_cache(cache_key)
        
        if cached_students:
            current_app.logger.info("Students served from cache")
            REQUEST_COUNT.labels(method='GET', endpoint='/students', status='200').inc()
            return jsonify(cached_students), 200
        
        # If not in cache, get from database
        students = Student.query.all()
        students_data = [student.to_dict() for student in students]
        
        # Cache the result
        set_cache(cache_key, students_data, timeout=300)  # Cache for 5 minutes
        
        REQUEST_COUNT.labels(method='GET', endpoint='/students', status='200').inc()
        return jsonify(students_data), 200
        
    except Exception as e:
        REQUEST_COUNT.labels(method='GET', endpoint='/students', status='500').inc()
        current_app.logger.error("Failed to fetch students", exc_info=True)
        return jsonify({"error": "Failed to fetch students"}), 500
    finally:
        REQUEST_LATENCY.labels(endpoint='/students').observe(time.time() - start_time)

# GET: Retrieve a specific student by ID
@api_bp.route('/students/<int:student_id>', methods=['GET'])
def get_student(student_id):
    start_time = time.time()
    try:
        current_app.logger.info("Fetching student", extra={"student_id": student_id})
        
        # Try cache first
        cache_key = f"students:id:{student_id}"
        cached_student = get_from_cache(cache_key)
        
        if cached_student:
            current_app.logger.info("Student served from cache", extra={"student_id": student_id})
            REQUEST_COUNT.labels(method='GET', endpoint='/students/<id>', status='200').inc()
            return jsonify(cached_student), 200
        
        student = Student.query.get(student_id)
        if not student:
            REQUEST_COUNT.labels(method='GET', endpoint='/students/<id>', status='404').inc()
            return jsonify({"error": "Student not found"}), 404
            
        student_data = student.to_dict()
        
        # Cache the result
        set_cache(cache_key, student_data, timeout=300)
        
        REQUEST_COUNT.labels(method='GET', endpoint='/students/<id>', status='200').inc()
        return jsonify(student_data), 200
        
    except Exception as e:
        REQUEST_COUNT.labels(method='GET', endpoint='/students/<id>', status='500').inc()
        current_app.logger.error("Failed to fetch student", exc_info=True)
        return jsonify({"error": "Failed to fetch student"}), 500
    finally:
        REQUEST_LATENCY.labels(endpoint='/students/<id>').observe(time.time() - start_time)

# PUT: Update a student
@api_bp.route('/students/<int:student_id>', methods=['PUT'])
def update_student(student_id):
    start_time = time.time()
    try:
        data = request.get_json()
        current_app.logger.info("Updating student", extra={"student_id": student_id})
        
        student = Student.query.get(student_id)
        if not student:
            REQUEST_COUNT.labels(method='PUT', endpoint='/students/<id>', status='404').inc()
            return jsonify({"error": "Student not found"}), 404
            
        # Update fields if provided
        if 'name' in data:
            student.name = data['name']
        if 'email' in data:
            student.email = data['email']
        if 'age' in data:
            student.age = data['age']
            
        db.session.commit()
        
        # Clear relevant cache entries
        delete_cache_pattern('students:*')
        
        current_app.logger.info(f"Student updated", extra={"student_id": student.id})
        REQUEST_COUNT.labels(method='PUT', endpoint='/students/<id>', status='200').inc()
        return jsonify(student.to_dict()), 200
        
    except Exception as e:
        REQUEST_COUNT.labels(method='PUT', endpoint='/students/<id>', status='500').inc()
        current_app.logger.error("Student update failed", exc_info=True)
        return jsonify({"error": "Failed to update student"}), 500
    finally:
        REQUEST_LATENCY.labels(endpoint='/students/<id>').observe(time.time() - start_time)

# DELETE: Delete a student
@api_bp.route('/students/<int:student_id>', methods=['DELETE'])
def delete_student(student_id):
    start_time = time.time()
    try:
        current_app.logger.info("Deleting student", extra={"student_id": student_id})
        student = Student.query.get(student_id)
        if not student:
            REQUEST_COUNT.labels(method='DELETE', endpoint='/students/<id>', status='404').inc()
            return jsonify({"error": "Student not found"}), 404
            
        db.session.delete(student)
        db.session.commit()
        
        # Clear relevant cache entries
        delete_cache_pattern('students:*')
        
        current_app.logger.info(f"Student deleted", extra={"student_id": student_id})
        REQUEST_COUNT.labels(method='DELETE', endpoint='/students/<id>', status='200').inc()
        return jsonify({"message": "Student deleted successfully"}), 200
        
    except Exception as e:
        REQUEST_COUNT.labels(method='DELETE', endpoint='/students/<id>', status='500').inc()
        current_app.logger.error("Student deletion failed", exc_info=True)
        return jsonify({"error": "Failed to delete student"}), 500
    finally:
        REQUEST_LATENCY.labels(endpoint='/students/<id>').observe(time.time() - start_time)

# Healthcheck endpoint
@api_bp.route('/healthcheck', methods=['GET'])
def healthcheck():
    """Healthcheck endpoint to ensure the API is alive and well"""
    start_time = time.time()
    try:
        # Check database connection
        db.session.execute('SELECT 1')
        
        # Check Redis connection if available
        redis_status = "unavailable"
        if current_app.redis:
            try:
                current_app.redis.ping()
                redis_status = "healthy"
            except:
                redis_status = "unhealthy"
        
        REQUEST_COUNT.labels(method='GET', endpoint='/healthcheck', status='200').inc()
        return jsonify({
            "status": "healthy",
            "database": "healthy",
            "redis": redis_status,
            "timestamp": time.time()
        }), 200
    except Exception as e:
        REQUEST_COUNT.labels(method='GET', endpoint='/healthcheck', status='500').inc()
        return jsonify({"status": "unhealthy", "error": str(e)}), 500
    finally:
        REQUEST_LATENCY.labels(endpoint='/healthcheck').observe(time.time() - start_time)

# Metrics endpoint for Prometheus
@api_bp.route('/metrics', methods=['GET'])
def metrics_endpoint():
    """Prometheus metrics endpoint"""
    with metrics_lock:
        # Calculate average response time
        avg_response_time = 0
        if metrics['http_request_duration_seconds']:
            avg_response_time = sum(metrics['http_request_duration_seconds']) / len(metrics['http_request_duration_seconds'])
        
        # Generate Prometheus format metrics
        prometheus_metrics = f"""# HELP flask_http_requests_total Total number of HTTP requests
# TYPE flask_http_requests_total counter
flask_http_requests_total {metrics['http_requests_total']}

# HELP flask_http_request_duration_seconds HTTP request duration in seconds
# TYPE flask_http_request_duration_seconds gauge
flask_http_request_duration_seconds {avg_response_time}

# HELP flask_active_connections Currently active connections
# TYPE flask_active_connections gauge
flask_active_connections {metrics['active_connections']}

# HELP flask_database_connections Database connections
# TYPE flask_database_connections gauge
flask_database_connections {metrics['database_connections']}
"""
    
    return Response(prometheus_metrics, mimetype='text/plain')

# Health check with database connectivity
@api_bp.route('/ready', methods=['GET'])
def readiness_check():
    """Readiness check including database connectivity"""
    try:
        # Test database connection
        db.session.execute('SELECT 1')
        with metrics_lock:
            metrics['database_connections'] = 1  # Simplified metric
        return jsonify({
            "status": "ready",
            "database": "connected",
            "timestamp": time.time()
        }), 200
    except Exception as e:
        current_app.logger.error("Database connection failed", exc_info=True)
        with metrics_lock:
            metrics['database_connections'] = 0
        return jsonify({
            "status": "not ready",
            "database": "disconnected",
            "error": str(e)
        }), 503

# Cache stats endpoint
@api_bp.route('/cache/stats', methods=['GET'])
def cache_stats():
    """Get Redis cache statistics"""
    if not current_app.redis:
        return jsonify({"error": "Redis not available"}), 503
    
    try:
        info = current_app.redis.info()
        stats = {
            "connected_clients": info.get('connected_clients', 0),
            "used_memory": info.get('used_memory_human', '0B'),
            "total_commands_processed": info.get('total_commands_processed', 0),
            "keyspace_hits": info.get('keyspace_hits', 0),
            "keyspace_misses": info.get('keyspace_misses', 0),
            "uptime_in_seconds": info.get('uptime_in_seconds', 0)
        }
        
        # Calculate hit ratio
        hits = stats['keyspace_hits']
        misses = stats['keyspace_misses']
        if hits + misses > 0:
            stats['hit_ratio'] = hits / (hits + misses)
        else:
            stats['hit_ratio'] = 0
        
        return jsonify(stats), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
