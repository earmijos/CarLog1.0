import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import '../config/app_config.dart';

/// API Response wrapper for consistent error handling.
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
  });

  factory ApiResponse.success(T data, int statusCode) {
    return ApiResponse(success: true, data: data, statusCode: statusCode);
  }

  factory ApiResponse.failure(String error, int statusCode) {
    return ApiResponse(success: false, error: error, statusCode: statusCode);
  }
}

/// API Exception for network errors.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message';
}

/// Main API Service for CarLog app.
/// Handles all HTTP communication with the backend.
class ApiService {
  static String baseUrl = AppConfig.apiBaseUrl;
  static const String apiPrefix = '/api';

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // ===========================================================================
  // Helper Methods
  // ===========================================================================

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final uri = Uri.parse('$baseUrl$apiPrefix$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(
        queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())),
      );
    }
    return uri;
  }

  Future<Map<String, dynamic>> _get(String path,
      [Map<String, dynamic>? queryParams]) async {
    try {
      final response = await _client.get(
        _buildUri(path, queryParams),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _client.post(
        _buildUri(path),
        headers: _headers,
        body: json.encode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    try {
      final response = await _client.put(
        _buildUri(path),
        headers: _headers,
        body: json.encode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    try {
      final response = await _client.delete(
        _buildUri(path),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final error = body['error'] ?? 'Unknown error';
    throw ApiException(error is String ? error : error.toString(), response.statusCode);
  }

  // ===========================================================================
  // Vehicle Endpoints
  // ===========================================================================

  /// Get all vehicles
  Future<List<Vehicle>> getVehicles({int limit = 100, int offset = 0}) async {
    final response = await _get('/vehicles', {'limit': limit, 'offset': offset});
    final data = response['data'] as List<dynamic>;
    return data.map((v) => Vehicle.fromJson(v)).toList();
  }

  /// Get vehicle by VIN
  Future<Vehicle?> getVehicleByVin(String vin) async {
    try {
      final response = await _get('/vehicles/$vin');
      if (response['success'] == true && response['data'] != null) {
        return Vehicle.fromJson(response['data']);
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Get vehicle summary with stats
  Future<VehicleSummary?> getVehicleSummary(String vin) async {
    try {
      final response = await _get('/vehicles/$vin/summary');
      if (response['success'] == true && response['data'] != null) {
        return VehicleSummary.fromJson(response['data']);
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Create a new vehicle
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    final response = await _post('/vehicles', vehicle.toJson());
    return Vehicle.fromJson(response['data']);
  }

  /// Update a vehicle
  Future<Vehicle> updateVehicle(String vin, Map<String, dynamic> data) async {
    final response = await _put('/vehicles/$vin', data);
    return Vehicle.fromJson(response['data']);
  }

  /// Delete a vehicle
  Future<bool> deleteVehicle(String vin) async {
    final response = await _delete('/vehicles/$vin');
    return response['success'] == true;
  }

  /// Update vehicle mileage
  Future<Vehicle> updateMileage(String vin, int mileage) async {
    final response = await _put('/vehicles/$vin/mileage', {'mileage': mileage});
    return Vehicle.fromJson(response['data']);
  }

  /// Search vehicles
  Future<List<Vehicle>> searchVehicles(String query, {int limit = 20}) async {
    final response = await _get('/vehicles/search', {'q': query, 'limit': limit});
    final data = response['data'] as List<dynamic>;
    return data.map((v) => Vehicle.fromJson(v)).toList();
  }

  // ===========================================================================
  // Repair Endpoints
  // ===========================================================================

  /// Get repairs for a vehicle
  Future<List<Repair>> getRepairsByVin(String vin, {int limit = 50}) async {
    final response = await _get('/repairs/vehicle/$vin', {'limit': limit});
    final data = response['data'] as List<dynamic>;
    return data.map((r) => Repair.fromJson(r)).toList();
  }

  /// Get a single repair
  Future<Repair?> getRepair(int id) async {
    try {
      final response = await _get('/repairs/$id');
      if (response['success'] == true && response['data'] != null) {
        return Repair.fromJson(response['data']);
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Create a new repair
  Future<Repair> createRepair(Repair repair) async {
    final response = await _post('/repairs', repair.toJson());
    return Repair.fromJson(response['data']);
  }

  /// Update a repair
  Future<Repair> updateRepair(int id, Map<String, dynamic> data) async {
    final response = await _put('/repairs/$id', data);
    return Repair.fromJson(response['data']);
  }

  /// Delete a repair
  Future<bool> deleteRepair(int id) async {
    final response = await _delete('/repairs/$id');
    return response['success'] == true;
  }

  /// Get repair cost summary
  Future<RepairCostSummary> getRepairSummary(String vin) async {
    final response = await _get('/repairs/vehicle/$vin/summary');
    return RepairCostSummary.fromJson(response['data']);
  }

  // ===========================================================================
  // Fuel Log Endpoints
  // ===========================================================================

  /// Get fuel logs for a vehicle
  Future<List<FuelLog>> getFuelLogsByVin(String vin, {int limit = 50}) async {
    final response = await _get('/fuel-logs/vehicle/$vin', {'limit': limit});
    final data = response['data'] as List<dynamic>;
    return data.map((f) => FuelLog.fromJson(f)).toList();
  }

  /// Get a single fuel log
  Future<FuelLog?> getFuelLog(int id) async {
    try {
      final response = await _get('/fuel-logs/$id');
      if (response['success'] == true && response['data'] != null) {
        return FuelLog.fromJson(response['data']);
      }
      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Create a new fuel log
  Future<FuelLog> createFuelLog(FuelLog fuelLog) async {
    final response = await _post('/fuel-logs', fuelLog.toJson());
    return FuelLog.fromJson(response['data']);
  }

  /// Update a fuel log
  Future<FuelLog> updateFuelLog(int id, Map<String, dynamic> data) async {
    final response = await _put('/fuel-logs/$id', data);
    return FuelLog.fromJson(response['data']);
  }

  /// Delete a fuel log
  Future<bool> deleteFuelLog(int id) async {
    final response = await _delete('/fuel-logs/$id');
    return response['success'] == true;
  }

  /// Get MPG data for a vehicle
  Future<MpgData> getMpg(String vin) async {
    final response = await _get('/fuel-logs/vehicle/$vin/mpg');
    return MpgData.fromJson(response['data']);
  }

  /// Get fuel cost summary
  Future<FuelCostSummary> getFuelSummary(String vin) async {
    final response = await _get('/fuel-logs/vehicle/$vin/summary');
    return FuelCostSummary.fromJson(response['data']);
  }

  // ===========================================================================
  // Maintenance Endpoints
  // ===========================================================================

  /// Get maintenance schedule for a vehicle
  Future<MaintenanceSchedule> getMaintenanceSchedule(String vin) async {
    final response = await _get('/maintenance/vehicle/$vin');
    return MaintenanceSchedule.fromJson(response['data']);
  }

  /// Get maintenance intervals for a vehicle (legacy format)
  Future<Map<String, dynamic>?> getMaintenanceByVin(String vin) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/maintenance/$vin'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create a maintenance interval
  Future<MaintenanceInterval> createMaintenance(MaintenanceInterval interval) async {
    final response = await _post('/maintenance', interval.toJson());
    return MaintenanceInterval.fromJson(response['data']);
  }

  /// Update a maintenance interval
  Future<MaintenanceInterval> updateMaintenance(int id, Map<String, dynamic> data) async {
    final response = await _put('/maintenance/$id', data);
    return MaintenanceInterval.fromJson(response['data']);
  }

  /// Delete a maintenance interval
  Future<bool> deleteMaintenance(int id) async {
    final response = await _delete('/maintenance/$id');
    return response['success'] == true;
  }

  /// Record a maintenance service
  Future<MaintenanceInterval> recordService(
    String vin,
    String serviceType, {
    String? date,
    int? mileage,
  }) async {
    final response = await _post('/maintenance/vehicle/$vin/record', {
      'service_type': serviceType,
      if (date != null) 'date': date,
      if (mileage != null) 'mileage': mileage,
    });
    return MaintenanceInterval.fromJson(response['data']);
  }

  /// Get upcoming maintenance
  Future<List<MaintenanceInterval>> getUpcomingMaintenance(String vin, {int limit = 5}) async {
    final response = await _get('/maintenance/vehicle/$vin/upcoming', {'limit': limit});
    final data = response['data'] as List<dynamic>;
    return data.map((m) => MaintenanceInterval.fromJson(m)).toList();
  }

  /// Get overdue maintenance
  Future<List<MaintenanceInterval>> getOverdueMaintenance(String vin) async {
    final response = await _get('/maintenance/vehicle/$vin/overdue');
    final data = response['data'] as List<dynamic>;
    return data.map((m) => MaintenanceInterval.fromJson(m)).toList();
  }

  // ===========================================================================
  // Trip Endpoints
  // ===========================================================================

  /// Get trips for a vehicle
  Future<List<Trip>> getTripsByVin(String vin, {int limit = 50}) async {
    final response = await _get('/trips/vehicle/$vin', {'limit': limit});
    final data = response['data'] as List<dynamic>;
    return data.map((t) => Trip.fromJson(t)).toList();
  }

  /// Create a new trip
  Future<Trip> createTrip(Trip trip) async {
    final response = await _post('/trips', trip.toJson());
    return Trip.fromJson(response['data']);
  }

  /// Update a trip
  Future<Trip> updateTrip(int id, Map<String, dynamic> data) async {
    final response = await _put('/trips/$id', data);
    return Trip.fromJson(response['data']);
  }

  /// Delete a trip
  Future<bool> deleteTrip(int id) async {
    final response = await _delete('/trips/$id');
    return response['success'] == true;
  }

  /// Get trip summary
  Future<TripSummary> getTripSummary(String vin, {int? year}) async {
    final params = <String, dynamic>{};
    if (year != null) params['year'] = year;
    final response = await _get('/trips/vehicle/$vin/summary', params);
    return TripSummary.fromJson(response['data']);
  }

  /// Get business trips
  Future<List<Trip>> getBusinessTrips(String vin, {int? year}) async {
    final params = <String, dynamic>{};
    if (year != null) params['year'] = year;
    final response = await _get('/trips/vehicle/$vin/business', params);
    final data = response['data'] as List<dynamic>;
    return data.map((t) => Trip.fromJson(t)).toList();
  }

  // ===========================================================================
  // Mileage Endpoints
  // ===========================================================================

  /// Get mileage history for a vehicle
  Future<List<MileageEntry>> getMileageHistory(String vin, {int limit = 50}) async {
    final response = await _get('/mileage/vehicle/$vin', {'limit': limit});
    final data = response['data'] as List<dynamic>;
    return data.map((m) => MileageEntry.fromJson(m)).toList();
  }

  /// Create a mileage entry
  Future<MileageEntry> createMileageEntry(MileageEntry entry) async {
    final response = await _post('/mileage', entry.toJson());
    return MileageEntry.fromJson(response['data']);
  }

  /// Delete a mileage entry
  Future<bool> deleteMileageEntry(int id) async {
    final response = await _delete('/mileage/$id');
    return response['success'] == true;
  }

  /// Get average daily miles
  Future<DailyMilesStats> getAverageDailyMiles(String vin, {int days = 30}) async {
    final response = await _get('/mileage/vehicle/$vin/average', {'days': days});
    return DailyMilesStats.fromJson(response['data']);
  }

  /// Get monthly mileage summary
  Future<List<MonthlyMileage>> getMonthlyMileage(String vin, {int months = 6}) async {
    final response = await _get('/mileage/vehicle/$vin/monthly', {'months': months});
    final data = response['data'] as List<dynamic>;
    return data.map((m) => MonthlyMileage.fromJson(m)).toList();
  }

  // ===========================================================================
  // Analytics Endpoints
  // ===========================================================================

  /// Get vehicle dashboard data
  Future<VehicleDashboard> getDashboard(String vin) async {
    final response = await _get('/analytics/dashboard/$vin');
    return VehicleDashboard.fromJson(response['data']);
  }

  /// Get cost per mile data
  Future<CostPerMileData> getCostPerMile(String vin) async {
    final response = await _get('/analytics/cost-per-mile/$vin');
    return CostPerMileData.fromJson(response['data']);
  }

  /// Get monthly spending
  Future<List<MonthlySpending>> getMonthlySpending(String vin, {int months = 12}) async {
    final response = await _get('/analytics/spending/$vin', {'months': months});
    final data = response['data'] as List<dynamic>;
    return data.map((s) => MonthlySpending.fromJson(s)).toList();
  }

  /// Get spending by category
  Future<List<CategorySpending>> getSpendingByCategory(String vin) async {
    final response = await _get('/analytics/spending-by-category/$vin');
    final data = response['data'] as List<dynamic>;
    return data.map((c) => CategorySpending.fromJson(c)).toList();
  }

  /// Get fuel price trend
  Future<List<FuelPriceTrend>> getFuelPriceTrend(String vin, {int months = 6}) async {
    final response = await _get('/analytics/fuel-prices/$vin', {'months': months});
    final data = response['data'] as List<dynamic>;
    return data.map((f) => FuelPriceTrend.fromJson(f)).toList();
  }

  /// Get all vehicles summary
  Future<List<VehicleSummaryItem>> getAllVehiclesSummary() async {
    final response = await _get('/analytics/summary');
    final data = response['data'] as List<dynamic>;
    return data.map((v) => VehicleSummaryItem.fromJson(v)).toList();
  }

  // ===========================================================================
  // Settings Endpoints
  // ===========================================================================

  /// Get all settings
  Future<AppSettings> getSettings() async {
    final response = await _get('/settings');
    return AppSettings.fromJson(response['data']);
  }

  /// Get a specific setting
  Future<String?> getSetting(String key) async {
    final response = await _get('/settings/$key');
    return response['data']?['value'];
  }

  /// Set a setting
  Future<void> setSetting(String key, String value) async {
    await _put('/settings/$key', {'value': value});
  }

  /// Get theme setting
  Future<String> getTheme() async {
    final response = await _get('/settings/theme');
    return response['data']?['theme'] ?? 'light';
  }

  /// Set theme
  Future<void> setTheme(String theme) async {
    await _put('/settings/theme', {'theme': theme});
  }

  /// Get unit settings
  Future<UnitSettings> getUnits() async {
    final response = await _get('/settings/units');
    return UnitSettings.fromJson(response['data']);
  }

  // ===========================================================================
  // User Endpoints
  // ===========================================================================

  /// Get default user
  Future<User> getDefaultUser() async {
    final response = await _get('/users/default');
    return User.fromJson(response['data']);
  }

  /// Get user stats
  Future<UserStats> getUserStats(int userId) async {
    final response = await _get('/users/$userId/stats');
    return UserStats.fromJson(response['data']);
  }

  /// Get user vehicles
  Future<List<Vehicle>> getUserVehicles(int userId) async {
    final response = await _get('/users/$userId/vehicles');
    final data = response['data'] as List<dynamic>;
    return data.map((v) => Vehicle.fromJson(v)).toList();
  }

  // ===========================================================================
  // Legacy Endpoints (for backward compatibility with existing screens)
  // ===========================================================================

  /// Legacy: Get vehicle by VIN (returns Map for backward compatibility)
  Future<Map<String, dynamic>?> getVehicleByVinLegacy(String vin) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/car/$vin'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load vehicle: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Legacy: Get repairs by VIN (returns List<Map> for backward compatibility)
  Future<List<Map<String, dynamic>>> getRepairsByVinLegacy(String vin) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/repair/repairs/$vin'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load repairs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Legacy: Add repair (used by existing AddRepairScreen)
  Future<bool> addRepair({
    required String vin,
    required String service,
    required double cost,
    required String date,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/repair/repairs'),
        headers: _headers,
        body: json.encode({
          'vin': vin,
          'service': service,
          'cost': cost,
          'date': date,
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
