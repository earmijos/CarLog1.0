import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service to decode VINs using the free NHTSA API
/// National Highway Traffic Safety Administration Vehicle API
class VinDecoderService {
  static const String _baseUrl = 'https://vpic.nhtsa.dot.gov/api/vehicles';

  /// Decode a VIN and return vehicle information
  /// Returns null if VIN is invalid or not found
  static Future<VinDecodeResult?> decodeVin(String vin) async {
    if (vin.length != 17) {
      return null;
    }

    try {
      final url = Uri.parse('$_baseUrl/decodevin/$vin?format=json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['Results'] as List<dynamic>;

        // Parse the results into a map
        final Map<String, String?> decoded = {};
        for (var item in results) {
          final variable = item['Variable'] as String?;
          final value = item['Value'] as String?;
          if (variable != null && value != null && value.isNotEmpty) {
            decoded[variable] = value;
          }
        }

        // Check if we got valid data (at least make or model)
        if (decoded['Make'] == null && decoded['Model'] == null) {
          return null;
        }

        return VinDecodeResult(
          vin: vin.toUpperCase(),
          make: decoded['Make'],
          model: decoded['Model'],
          year: int.tryParse(decoded['Model Year'] ?? ''),
          trim: decoded['Trim'],
          bodyClass: decoded['Body Class'],
          vehicleType: decoded['Vehicle Type'],
          driveType: decoded['Drive Type'],
          fuelType: decoded['Fuel Type - Primary'],
          engineCylinders: int.tryParse(decoded['Engine Number of Cylinders'] ?? ''),
          engineDisplacement: decoded['Displacement (L)'],
          transmissionStyle: decoded['Transmission Style'],
          doors: int.tryParse(decoded['Doors'] ?? ''),
          plantCountry: decoded['Plant Country'],
          plantCity: decoded['Plant City'],
          manufacturer: decoded['Manufacturer Name'],
          errorCode: decoded['Error Code'],
          errorText: decoded['Error Text'],
        );
      }
    } catch (e) {
      print('VIN decode error: $e');
    }

    return null;
  }

  /// Get extended vehicle info (more detailed)
  static Future<List<VehicleVariant>?> getVehicleVariants(
    String year,
    String make,
    String model,
  ) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/getmodelsformakeyear/make/$make/modelyear/$year?format=json',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['Results'] as List<dynamic>;

        return results
            .where((item) =>
                (item['Model_Name'] as String?)
                    ?.toLowerCase()
                    .contains(model.toLowerCase()) ??
                false)
            .map((item) => VehicleVariant(
                  makeId: item['Make_ID']?.toString(),
                  makeName: item['Make_Name'] as String?,
                  modelId: item['Model_ID']?.toString(),
                  modelName: item['Model_Name'] as String?,
                ))
            .toList();
      }
    } catch (e) {
      print('Vehicle variants error: $e');
    }

    return null;
  }

  /// Get all makes for a specific year
  static Future<List<String>> getMakesForYear(int year) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/getmakesforyear/year/$year?format=json',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['Results'] as List<dynamic>;

        return results
            .map((item) => item['Make_Name'] as String)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
      }
    } catch (e) {
      print('Makes for year error: $e');
    }

    return [];
  }

  /// Get all models for a make and year
  static Future<List<String>> getModelsForMakeYear(String make, int year) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/getmodelsformakeyear/make/$make/modelyear/$year?format=json',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['Results'] as List<dynamic>;

        return results
            .map((item) => item['Model_Name'] as String)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
      }
    } catch (e) {
      print('Models for make/year error: $e');
    }

    return [];
  }
}

/// Result of a VIN decode operation
class VinDecodeResult {
  final String vin;
  final String? make;
  final String? model;
  final int? year;
  final String? trim;
  final String? bodyClass;
  final String? vehicleType;
  final String? driveType;
  final String? fuelType;
  final int? engineCylinders;
  final String? engineDisplacement;
  final String? transmissionStyle;
  final int? doors;
  final String? plantCountry;
  final String? plantCity;
  final String? manufacturer;
  final String? errorCode;
  final String? errorText;

  VinDecodeResult({
    required this.vin,
    this.make,
    this.model,
    this.year,
    this.trim,
    this.bodyClass,
    this.vehicleType,
    this.driveType,
    this.fuelType,
    this.engineCylinders,
    this.engineDisplacement,
    this.transmissionStyle,
    this.doors,
    this.plantCountry,
    this.plantCity,
    this.manufacturer,
    this.errorCode,
    this.errorText,
  });

  /// Get a display name for the vehicle
  String get displayName {
    final parts = <String>[];
    if (year != null) parts.add(year.toString());
    if (make != null) parts.add(make!);
    if (model != null) parts.add(model!);
    if (trim != null && trim!.isNotEmpty) parts.add(trim!);
    return parts.isEmpty ? 'Unknown Vehicle' : parts.join(' ');
  }

  /// Check if this is a valid decode (no major errors)
  bool get isValid {
    return make != null && model != null && (errorCode == '0' || errorCode == null);
  }

  /// Get engine description
  String? get engineDescription {
    if (engineCylinders != null && engineDisplacement != null) {
      return '${engineDisplacement}L ${engineCylinders}-cylinder';
    } else if (engineCylinders != null) {
      return '${engineCylinders}-cylinder';
    } else if (engineDisplacement != null) {
      return '${engineDisplacement}L';
    }
    return null;
  }
}

/// A vehicle variant/model option
class VehicleVariant {
  final String? makeId;
  final String? makeName;
  final String? modelId;
  final String? modelName;

  VehicleVariant({
    this.makeId,
    this.makeName,
    this.modelId,
    this.modelName,
  });
}

