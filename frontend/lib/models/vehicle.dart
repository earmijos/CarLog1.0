/// Vehicle model for CarLog app.
class Vehicle {
  final String vin;
  final int year;
  final String make;
  final String model;
  final String? trim;
  final String? engineType;
  final String? color;
  final String? purchaseDate;
  final double? purchasePrice;
  final int currentMileage;
  final int? userId;
  final String? createdAt;
  final String? updatedAt;

  Vehicle({
    required this.vin,
    required this.year,
    required this.make,
    required this.model,
    this.trim,
    this.engineType,
    this.color,
    this.purchaseDate,
    this.purchasePrice,
    this.currentMileage = 0,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  /// Create from JSON (API response)
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      vin: json['vin'] ?? json['VIN'] ?? '',
      year: json['year'] ?? json['Year'] ?? 0,
      make: json['make'] ?? json['Make'] ?? '',
      model: json['model'] ?? json['Model'] ?? '',
      trim: json['trim'] ?? json['Trim'],
      engineType: json['engine_type'] ?? json['engineType'],
      color: json['color'],
      purchaseDate: json['purchase_date'],
      purchasePrice: json['purchase_price']?.toDouble(),
      currentMileage: json['current_mileage'] ?? 0,
      userId: json['user_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  /// Convert to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'vin': vin,
      'year': year,
      'make': make,
      'model': model,
      if (trim != null) 'trim': trim,
      if (engineType != null) 'engine_type': engineType,
      if (color != null) 'color': color,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (purchasePrice != null) 'purchase_price': purchasePrice,
      'current_mileage': currentMileage,
      if (userId != null) 'user_id': userId,
    };
  }

  /// Display name for the vehicle
  String get displayName => '$year $make $model${trim != null ? ' $trim' : ''}';

  /// Short display name
  String get shortName => '$make $model';

  /// Copy with modifications
  Vehicle copyWith({
    String? vin,
    int? year,
    String? make,
    String? model,
    String? trim,
    String? engineType,
    String? color,
    String? purchaseDate,
    double? purchasePrice,
    int? currentMileage,
    int? userId,
  }) {
    return Vehicle(
      vin: vin ?? this.vin,
      year: year ?? this.year,
      make: make ?? this.make,
      model: model ?? this.model,
      trim: trim ?? this.trim,
      engineType: engineType ?? this.engineType,
      color: color ?? this.color,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentMileage: currentMileage ?? this.currentMileage,
      userId: userId ?? this.userId,
    );
  }

  @override
  String toString() => 'Vehicle($displayName, VIN: $vin)';
}

/// Vehicle summary with additional stats
class VehicleSummary extends Vehicle {
  final int repairCount;
  final double repairTotalCost;
  final int fuelLogCount;
  final double fuelTotalCost;
  final List<MaintenancePreview> upcomingMaintenance;

  VehicleSummary({
    required super.vin,
    required super.year,
    required super.make,
    required super.model,
    super.trim,
    super.engineType,
    super.color,
    super.purchaseDate,
    super.purchasePrice,
    super.currentMileage,
    super.userId,
    super.createdAt,
    super.updatedAt,
    this.repairCount = 0,
    this.repairTotalCost = 0,
    this.fuelLogCount = 0,
    this.fuelTotalCost = 0,
    this.upcomingMaintenance = const [],
  });

  factory VehicleSummary.fromJson(Map<String, dynamic> json) {
    return VehicleSummary(
      vin: json['vin'] ?? json['VIN'] ?? '',
      year: json['year'] ?? json['Year'] ?? 0,
      make: json['make'] ?? json['Make'] ?? '',
      model: json['model'] ?? json['Model'] ?? '',
      trim: json['trim'] ?? json['Trim'],
      engineType: json['engine_type'] ?? json['engineType'],
      color: json['color'],
      purchaseDate: json['purchase_date'],
      purchasePrice: json['purchase_price']?.toDouble(),
      currentMileage: json['current_mileage'] ?? 0,
      userId: json['user_id'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      repairCount: json['repair_count'] ?? 0,
      repairTotalCost: (json['repair_total_cost'] ?? 0).toDouble(),
      fuelLogCount: json['fuel_log_count'] ?? 0,
      fuelTotalCost: (json['fuel_total_cost'] ?? 0).toDouble(),
      upcomingMaintenance: (json['upcoming_maintenance'] as List<dynamic>?)
              ?.map((m) => MaintenancePreview.fromJson(m))
              .toList() ??
          [],
    );
  }

  double get totalCost => repairTotalCost + fuelTotalCost;
}

/// Lightweight maintenance preview for vehicle summary
class MaintenancePreview {
  final String serviceType;
  final int? nextDueMileage;

  MaintenancePreview({
    required this.serviceType,
    this.nextDueMileage,
  });

  factory MaintenancePreview.fromJson(Map<String, dynamic> json) {
    return MaintenancePreview(
      serviceType: json['service_type'] ?? '',
      nextDueMileage: json['next_due_mileage'],
    );
  }
}

