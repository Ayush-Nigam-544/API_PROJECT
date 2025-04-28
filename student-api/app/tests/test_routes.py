import json
import pytest

def test_create_student(client):
    """Test successful student creation"""
    response = client.post('/api/v1/students', json={
        "name": "Test User",
        "email": "test@example.com"
    })
    assert response.status_code == 201
    assert 'id' in response.json

def test_invalid_student(client):
    """Test missing required fields"""
    response = client.post('/api/v1/students', json={
        "name": "Missing Email"
    })
    assert response.status_code == 400
    assert 'error' in response.json

def test_healthcheck(client):
    """Test healthcheck endpoint"""
    response = client.get('/api/v1/healthcheck')
    assert response.status_code == 200
    assert response.json['status'] == 'healthy'

# Add more test cases...