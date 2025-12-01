/// Trip model for CarLog app.
class Trip {
  final int? id;
  final String vin;
  final String? startLocation;
  final String? endLocation;
  final int? startMileage;
  final int? endMileage;
  final double? distance;
  final String date;
  final String? purpose;
  final bool isBusiness;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  Trip({
    this.id,
    required this.vin,
    this.startLocation,
    this.endLocation,
    this.startMileage,
    this.endMileage,
    this.distance,
    required this.date,
    this.purpose,
    this.isBusiness = false,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'],
      vin: json['vin'] ?? '',
      startLocation: json['start_location'],
      endLocation: json['end_location'],
      startMileage: json['start_mileage'],
      endMileage: json['end_mileage'],
      distance: json['distance']?.toDouble(),
      date: json['date'] ?? '',
      purpose: json['purpose'],
      isBusiness: (json['is_business'] ?? 0) == 1,
      notes: json['notes'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'vin': vin,
      if (startLocation != null) 'start_location': startLocation,
      if (endLocation != null) 'end_location': endLocation,
      if (startMileage != null) 'start_mileage': startMileage,
      if (endMileage != null) 'end_mileage': endMileage,
      if (distance != null) 'distance': distance,
      'date': date,
      if (purpose != null) 'purpose': purpose,
      'is_business': isBusiness ? 1 : 0,
      if (notes != null) 'notes': notes,
    };
  }

  Trip copyWith({
    int? id,
    String? vin,
    String? startLocation,
    String? endLocation,
    int? startMileage,
    int? endMileage,
    double? distance,
    String? date,
    String? purpose,
    bool? isBusiness,
    String? notes,
  }) {
    return Trip(
      id: id ?? this.id,
      vin: vin ?? this.vin,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      startMileage: startMileage ?? this.startMileage,
      endMileage: endMileage ?? this.endMileage,
      distance: distance ?? this.distance,
      date: date ?? this.date,
      purpose: purpose ?? this.purpose,
      isBusiness: isBusiness ?? this.isBusiness,
      notes: notes ?? this.notes,
    );
  }

  /// Route display string
  String get routeDisplay {
    if (startLocation != null && endLocation != null) {
      return '$startLocation → $endLocation';
    }
    return 'Trip';
  }

  @override
  String toString() => 'Trip($routeDisplay, ${distance?.toStringAsFixed(1)} mi)';
}

/// Trip mileage summary
class TripSummary {
  final int totalTrips;
  final double totalMiles;
  final double businessMiles;
  final double personalMiles;
  final int businessTrips;
  final int personalTrips;

  TripSummary({
    required this.totalTrips,
    required this.totalMiles,
    required this.businessMiles,
    required this.personalMiles,
    required this.businessTrips,
    required this.personalTrips,
  });

  factory TripSummary.fromJson(Map<String, dynamic> json) {
    return TripSummary(
      totalTrips: json['total_trips'] ?? 0,
      totalMiles: (json['total_miles'] ?? 0).toDouble(),
      businessMiles: (json['business_miles'] ?? 0).toDouble(),
      personalMiles: (json['personal_miles'] ?? 0).toDouble(),
      businessTrips: json['business_trips'] ?? 0,
      personalTrips: json['personal_trips'] ?? 0,
    );
  }
}

/// Trip purpose breakdown
class PurposeBreakdown {
  final String purpose;
  final int tripCount;
  final double totalMiles;

  PurposeBreakdown({
    required this.purpose,
    required this.tripCount,
    required this.totalMiles,
  });

  factory PurposeBreakdown.fromJson(Map<String, dynamic> json) {
    return PurposeBreakdown(
      purpose: json['purpose'] ?? 'Unknown',
      tripCount: json['trip_count'] ?? 0,
      totalMiles: (json['total_miles'] ?? 0).toDouble(),
    );
  }
}

/// Common trip purposes
class TripPurposes {
  static const List<String> all = [
    'Commute',
    'Business',
    'Personal',
    'Road Trip',
    'Errand',
    'Medical',
    'Other',
  ];
}

