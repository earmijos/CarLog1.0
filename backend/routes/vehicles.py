"""
Vehicles API Routes
===================
RESTful endpoints for vehicle management.
"""

from flask import Blueprint, request, jsonify
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from services.vehicle_service import VehicleService
from services.base_service import ValidationError, NotFoundError

vehicles_bp = Blueprint('vehicles', __name__)


@vehicles_bp.route('', methods=['GET'])
def get_vehicles():
    """
    Get all vehicles.
    Query params: limit, offset, user_id
    """
    try:
        limit = request.args.get('limit', 100, type=int)
        offset = request.args.get('offset', 0, type=int)
        user_id = request.args.get('user_id', type=int)
        
        vehicles = VehicleService.get_all(limit=limit, offset=offset, user_id=user_id)
        
        return jsonify({
            'success': True,
            'data': vehicles,
            'count': len(vehicles)
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@vehicles_bp.route('/<vin>', methods=['GET'])
def get_vehicle(vin):
    """Get a single vehicle by VIN."""
    try:
        vehicle = VehicleService.get_by_vin(vin)
        
        if not vehicle:
            return jsonify({
                'success': False,
                'error': 'Vehicle not found'
            }), 404
        
        return jsonify({
            'success': True,
            'data': vehicle
        })
    except ValidationError as e:
        return jsonify({'success': False, 'error': e.message}), 400
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@vehicles_bp.route('/<vin>/summary', methods=['GET'])
def get_vehicle_summary(vin):
    """Get vehicle summary with stats."""
    try:
        summary = VehicleService.get_summary(vin)
        
        return jsonify({
            'success': True,
            'data': summary
        })
    except NotFoundError as e:
        return jsonify({'success': False, 'error': e.message}), 404
    except ValidationError as e:
        return jsonify({'success': False, 'error': e.message}), 400
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@vehicles_bp.route('', methods=['POST'])
def create_vehicle():
    """Create a new vehicle."""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'error': 'No data provided'
            }), 400
        
        vehicle = VehicleService.create(data)
        
        return jsonify({
            'success': True,
            'data': vehicle,
            'message': 'Vehicle created successfully'
        }), 201
    except ValidationError as e:
        return jsonify({'success': False, 'error': e.message}), 400
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@vehicles_bp.route('/<vin>', methods=['PUT', 'PATCH'])
def update_vehicle(vin):
    """Update a vehicle."""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'success': False,
                'error': 'No data provided'
            }), 400
        
        vehicle = VehicleService.update(vin, data)
        
        return jsonify({
            'success': True,
            'data': vehicle,
            'message': 'Vehicle updated successfully'
        })
    except NotFoundError as e:
        return jsonify({'success': False, 'error': e.message}), 404
    except ValidationError as e:
        return jsonify({'success': False, 'error': e.message}), 400
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@vehicles_bp.route('/<vin>', methods=['DELETE'])
def delete_vehicle(vin):
    """Delete a vehicle."""
    try:
        VehicleService.delete(vin)
        
        return jsonify({
            'success': True,
            'message': 'Vehicle deleted successfully'
        })
    except NotFoundError as e:
        return jsonify({'success': False, 'error': e.message}), 404
    except ValidationError as e:
        return jsonify({'success': False, 'error': e.message}), 400
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@vehicles_bp.route('/<vin>/mileage', methods=['PUT'])
def update_mileage(vin):
    """Update vehicle mileage."""
    try:
        data = request.get_json()
        mileage = data.get('mileage') if data else None
        
        if mileage is None:
            return jsonify({
                'success': False,
                'error': 'Mileage is required'
            }), 400
        
        vehicle = VehicleService.update_mileage(vin, mileage)
        
        return jsonify({
            'success': True,
            'data': vehicle,
            'message': 'Mileage updated successfully'
        })
    except NotFoundError as e:
        return jsonify({'success': False, 'error': e.message}), 404
    except ValidationError as e:
        return jsonify({'success': False, 'error': e.message}), 400
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@vehicles_bp.route('/search', methods=['GET'])
def search_vehicles():
    """Search vehicles by make, model, or VIN."""
    try:
        query = request.args.get('q', '')
        limit = request.args.get('limit', 20, type=int)
        
        if not query:
            return jsonify({
                'success': False,
                'error': 'Search query is required'
            }), 400
        
        vehicles = VehicleService.search(query, limit=limit)
        
        return jsonify({
            'success': True,
            'data': vehicles,
            'count': len(vehicles)
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

