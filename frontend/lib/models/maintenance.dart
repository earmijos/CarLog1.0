/// Maintenance interval model for CarLog app.
class MaintenanceInterval {
  final int? id;
  final String vin;
  final String serviceType;
  final int? intervalMiles;
  final int? intervalMonths;
  final String? lastPerformedDate;
  final int? lastPerformedMileage;
  final String? nextDueDate;
  final int? nextDueMileage;
  final bool isCustom;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  // Calculated fields (from schedule endpoint)
  final int? milesUntilDue;
  final MaintenanceStatus status;

  MaintenanceInterval({
    this.id,
    required this.vin,
    required this.serviceType,
    this.intervalMiles,
    this.intervalMonths,
    this.lastPerformedDate,
    this.lastPerformedMileage,
    this.nextDueDate,
    this.nextDueMileage,
    this.isCustom = false,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.milesUntilDue,
    this.status = MaintenanceStatus.unknown,
  });

  factory MaintenanceInterval.fromJson(Map<String, dynamic> json) {
    return MaintenanceInterval(
      id: json['id'],
      vin: json['vin'] ?? json['VIN'] ?? '',
      serviceType: json['service_type'] ?? '',
      intervalMiles: json['interval_miles'],
      intervalMonths: json['interval_months'],
      lastPerformedDate: json['last_performed_date'],
      lastPerformedMileage: json['last_performed_mileage'],
      nextDueDate: json['next_due_date'],
      nextDueMileage: json['next_due_mileage'],
      isCustom: (json['is_custom'] ?? 0) == 1,
      notes: json['notes'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      milesUntilDue: json['miles_until_due'],
      status: _parseStatus(json['status']),
    );
  }

  static MaintenanceStatus _parseStatus(String? status) {
    switch (status) {
      case 'overdue':
        return MaintenanceStatus.overdue;
      case 'due_soon':
        return MaintenanceStatus.dueSoon;
      case 'ok':
        return MaintenanceStatus.ok;
      default:
        return MaintenanceStatus.unknown;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'vin': vin,
      'service_type': serviceType,
      if (intervalMiles != null) 'interval_miles': intervalMiles,
      if (intervalMonths != null) 'interval_months': intervalMonths,
      if (lastPerformedDate != null) 'last_performed_date': lastPerformedDate,
      if (lastPerformedMileage != null) 'last_performed_mileage': lastPerformedMileage,
      if (nextDueDate != null) 'next_due_date': nextDueDate,
      if (nextDueMileage != null) 'next_due_mileage': nextDueMileage,
      'is_custom': isCustom ? 1 : 0,
      if (notes != null) 'notes': notes,
    };
  }

  MaintenanceInterval copyWith({
    int? id,
    String? vin,
    String? serviceType,
    int? intervalMiles,
    int? intervalMonths,
    String? lastPerformedDate,
    int? lastPerformedMileage,
    String? nextDueDate,
    int? nextDueMileage,
    bool? isCustom,
    String? notes,
  }) {
    return MaintenanceInterval(
      id: id ?? this.id,
      vin: vin ?? this.vin,
      serviceType: serviceType ?? this.serviceType,
      intervalMiles: intervalMiles ?? this.intervalMiles,
      intervalMonths: intervalMonths ?? this.intervalMonths,
      lastPerformedDate: lastPerformedDate ?? this.lastPerformedDate,
      lastPerformedMileage: lastPerformedMileage ?? this.lastPerformedMileage,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      nextDueMileage: nextDueMileage ?? this.nextDueMileage,
      isCustom: isCustom ?? this.isCustom,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() => 'MaintenanceInterval($serviceType, every $intervalMiles miles)';
}

/// Maintenance status enum
enum MaintenanceStatus {
  overdue,
  dueSoon,
  ok,
  unknown,
}

/// Maintenance schedule for a vehicle
class MaintenanceSchedule {
  final String vin;
  final int currentMileage;
  final List<MaintenanceInterval> intervals;

  MaintenanceSchedule({
    required this.vin,
    required this.currentMileage,
    required this.intervals,
  });

  factory MaintenanceSchedule.fromJson(Map<String, dynamic> json) {
    return MaintenanceSchedule(
      vin: json['vin'] ?? '',
      currentMileage: json['current_mileage'] ?? 0,
      intervals: (json['intervals'] as List<dynamic>?)
              ?.map((i) => MaintenanceInterval.fromJson(i))
              .toList() ??
          [],
    );
  }

  /// Get overdue maintenance items
  List<MaintenanceInterval> get overdue =>
      intervals.where((i) => i.status == MaintenanceStatus.overdue).toList();

  /// Get items due soon
  List<MaintenanceInterval> get dueSoon =>
      intervals.where((i) => i.status == MaintenanceStatus.dueSoon).toList();

  /// Get items that are OK
  List<MaintenanceInterval> get ok =>
      intervals.where((i) => i.status == MaintenanceStatus.ok).toList();
}

/// Default maintenance service types
class MaintenanceTypes {
  static const List<String> all = [
    'Oil Change',
    'Transmission Fluid',
    'Brake Inspection',
    'Air Filter',
    'Tire Rotation',
    'Coolant Flush',
    'Spark Plugs',
    'Battery Check',
    'Brake Fluid',
    'Power Steering Fluid',
  ];
}

