/// App settings model for CarLog app.
class AppSettings {
  final String distanceUnit;
  final String fuelUnit;
  final String currency;
  final String currencySymbol;
  final String dateFormat;
  final String theme;
  final bool notificationsEnabled;
  final int maintenanceReminderMiles;
  final String fuelGradeDefault;

  AppSettings({
    this.distanceUnit = 'miles',
    this.fuelUnit = 'gallons',
    this.currency = 'USD',
    this.currencySymbol = '\$',
    this.dateFormat = 'YYYY-MM-DD',
    this.theme = 'light',
    this.notificationsEnabled = true,
    this.maintenanceReminderMiles = 500,
    this.fuelGradeDefault = 'Regular',
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      distanceUnit: json['distance_unit'] ?? 'miles',
      fuelUnit: json['fuel_unit'] ?? 'gallons',
      currency: json['currency'] ?? 'USD',
      currencySymbol: json['currency_symbol'] ?? '\$',
      dateFormat: json['date_format'] ?? 'YYYY-MM-DD',
      theme: json['theme'] ?? 'light',
      notificationsEnabled: json['notifications_enabled'] == 'true',
      maintenanceReminderMiles: int.tryParse(
              json['maintenance_reminder_miles']?.toString() ?? '500') ??
          500,
      fuelGradeDefault: json['fuel_grade_default'] ?? 'Regular',
    );
  }

  Map<String, String> toJson() {
    return {
      'distance_unit': distanceUnit,
      'fuel_unit': fuelUnit,
      'currency': currency,
      'currency_symbol': currencySymbol,
      'date_format': dateFormat,
      'theme': theme,
      'notifications_enabled': notificationsEnabled.toString(),
      'maintenance_reminder_miles': maintenanceReminderMiles.toString(),
      'fuel_grade_default': fuelGradeDefault,
    };
  }

  AppSettings copyWith({
    String? distanceUnit,
    String? fuelUnit,
    String? currency,
    String? currencySymbol,
    String? dateFormat,
    String? theme,
    bool? notificationsEnabled,
    int? maintenanceReminderMiles,
    String? fuelGradeDefault,
  }) {
    return AppSettings(
      distanceUnit: distanceUnit ?? this.distanceUnit,
      fuelUnit: fuelUnit ?? this.fuelUnit,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      dateFormat: dateFormat ?? this.dateFormat,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      maintenanceReminderMiles:
          maintenanceReminderMiles ?? this.maintenanceReminderMiles,
      fuelGradeDefault: fuelGradeDefault ?? this.fuelGradeDefault,
    );
  }

  /// Check if using metric units
  bool get isMetric => distanceUnit == 'kilometers';

  /// Get distance unit label
  String get distanceLabel => isMetric ? 'km' : 'mi';

  /// Get fuel unit label
  String get fuelLabel => fuelUnit == 'liters' ? 'L' : 'gal';

  /// Get fuel efficiency label
  String get efficiencyLabel => isMetric ? 'km/L' : 'MPG';
}

/// User model
class User {
  final int id;
  final String name;
  final String? email;
  final String? createdAt;
  final String? updatedAt;

  User({
    required this.id,
    required this.name,
    this.email,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (email != null) 'email': email,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }
}

/// User statistics
class UserStats {
  final int vehicleCount;
  final int repairCount;
  final double repairTotalCost;
  final int fuelLogCount;
  final double fuelTotalCost;
  final double totalCost;

  UserStats({
    required this.vehicleCount,
    required this.repairCount,
    required this.repairTotalCost,
    required this.fuelLogCount,
    required this.fuelTotalCost,
    required this.totalCost,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      vehicleCount: json['vehicle_count'] ?? 0,
      repairCount: json['repair_count'] ?? 0,
      repairTotalCost: (json['repair_total_cost'] ?? 0).toDouble(),
      fuelLogCount: json['fuel_log_count'] ?? 0,
      fuelTotalCost: (json['fuel_total_cost'] ?? 0).toDouble(),
      totalCost: (json['total_cost'] ?? 0).toDouble(),
    );
  }
}

/// Unit settings
class UnitSettings {
  final String distance;
  final String fuel;
  final String currency;
  final String currencySymbol;

  UnitSettings({
    required this.distance,
    required this.fuel,
    required this.currency,
    required this.currencySymbol,
  });

  factory UnitSettings.fromJson(Map<String, dynamic> json) {
    return UnitSettings(
      distance: json['distance'] ?? 'miles',
      fuel: json['fuel'] ?? 'gallons',
      currency: json['currency'] ?? 'USD',
      currencySymbol: json['currency_symbol'] ?? '\$',
    );
  }
}

/// Available themes
class AppThemes {
  static const String light = 'light';
  static const String dark = 'dark';
  static const String system = 'system';

  static const List<String> all = [light, dark, system];
}

/// Available distance units
class DistanceUnits {
  static const String miles = 'miles';
  static const String kilometers = 'kilometers';

  static const List<String> all = [miles, kilometers];
}

/// Available fuel units
class FuelUnits {
  static const String gallons = 'gallons';
  static const String liters = 'liters';

  static const List<String> all = [gallons, liters];
}

