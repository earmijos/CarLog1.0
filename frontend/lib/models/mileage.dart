/// Mileage history entry model for CarLog app.
class MileageEntry {
  final int? id;
  final String vin;
  final int mileage;
  final String date;
  final String source;
  final String? notes;
  final String? createdAt;

  MileageEntry({
    this.id,
    required this.vin,
    required this.mileage,
    required this.date,
    this.source = 'manual',
    this.notes,
    this.createdAt,
  });

  factory MileageEntry.fromJson(Map<String, dynamic> json) {
    return MileageEntry(
      id: json['id'],
      vin: json['vin'] ?? '',
      mileage: json['mileage'] ?? 0,
      date: json['date'] ?? '',
      source: json['source'] ?? 'manual',
      notes: json['notes'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'vin': vin,
      'mileage': mileage,
      'date': date,
      'source': source,
      if (notes != null) 'notes': notes,
    };
  }

  MileageEntry copyWith({
    int? id,
    String? vin,
    int? mileage,
    String? date,
    String? source,
    String? notes,
  }) {
    return MileageEntry(
      id: id ?? this.id,
      vin: vin ?? this.vin,
      mileage: mileage ?? this.mileage,
      date: date ?? this.date,
      source: source ?? this.source,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() => 'MileageEntry($mileage mi, $date)';
}

/// Average daily miles statistics
class DailyMilesStats {
  final double? averageDailyMiles;
  final int totalMiles;
  final int daysTracked;
  final int? estimatedYearlyMiles;
  final String? message;

  DailyMilesStats({
    this.averageDailyMiles,
    required this.totalMiles,
    required this.daysTracked,
    this.estimatedYearlyMiles,
    this.message,
  });

  factory DailyMilesStats.fromJson(Map<String, dynamic> json) {
    return DailyMilesStats(
      averageDailyMiles: json['average_daily_miles']?.toDouble(),
      totalMiles: json['total_miles'] ?? 0,
      daysTracked: json['days_tracked'] ?? 0,
      estimatedYearlyMiles: json['estimated_yearly_miles'],
      message: json['message'],
    );
  }

  bool get hasData => averageDailyMiles != null;
}

/// Monthly mileage summary
class MonthlyMileage {
  final String month;
  final int startMileage;
  final int endMileage;
  final int milesDriven;
  final int readings;

  MonthlyMileage({
    required this.month,
    required this.startMileage,
    required this.endMileage,
    required this.milesDriven,
    required this.readings,
  });

  factory MonthlyMileage.fromJson(Map<String, dynamic> json) {
    return MonthlyMileage(
      month: json['month'] ?? '',
      startMileage: json['start_mileage'] ?? 0,
      endMileage: json['end_mileage'] ?? 0,
      milesDriven: json['miles_driven'] ?? 0,
      readings: json['readings'] ?? 0,
    );
  }

  /// Get display month (e.g., "2024-01" -> "Jan 2024")
  String get displayMonth {
    try {
      final parts = month.split('-');
      final year = parts[0];
      final monthNum = int.parse(parts[1]);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[monthNum - 1]} $year';
    } catch (_) {
      return month;
    }
  }
}

