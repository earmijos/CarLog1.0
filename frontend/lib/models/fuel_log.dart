/// Fuel log model for CarLog app.
class FuelLog {
  final int? id;
  final String vin;
  final double gallons;
  final double pricePerGallon;
  final double totalCost;
  final int odometer;
  final String date;
  final String? station;
  final String fuelType;
  final bool fullTank;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  FuelLog({
    this.id,
    required this.vin,
    required this.gallons,
    required this.pricePerGallon,
    required this.totalCost,
    required this.odometer,
    required this.date,
    this.station,
    this.fuelType = 'Regular',
    this.fullTank = true,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory FuelLog.fromJson(Map<String, dynamic> json) {
    return FuelLog(
      id: json['id'],
      vin: json['vin'] ?? '',
      gallons: (json['gallons'] ?? 0).toDouble(),
      pricePerGallon: (json['price_per_gallon'] ?? 0).toDouble(),
      totalCost: (json['total_cost'] ?? 0).toDouble(),
      odometer: json['odometer'] ?? 0,
      date: json['date'] ?? '',
      station: json['station'],
      fuelType: json['fuel_type'] ?? 'Regular',
      fullTank: (json['full_tank'] ?? 1) == 1,
      notes: json['notes'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'vin': vin,
      'gallons': gallons,
      'price_per_gallon': pricePerGallon,
      'total_cost': totalCost,
      'odometer': odometer,
      'date': date,
      if (station != null) 'station': station,
      'fuel_type': fuelType,
      'full_tank': fullTank ? 1 : 0,
      if (notes != null) 'notes': notes,
    };
  }

  FuelLog copyWith({
    int? id,
    String? vin,
    double? gallons,
    double? pricePerGallon,
    double? totalCost,
    int? odometer,
    String? date,
    String? station,
    String? fuelType,
    bool? fullTank,
    String? notes,
  }) {
    return FuelLog(
      id: id ?? this.id,
      vin: vin ?? this.vin,
      gallons: gallons ?? this.gallons,
      pricePerGallon: pricePerGallon ?? this.pricePerGallon,
      totalCost: totalCost ?? this.totalCost,
      odometer: odometer ?? this.odometer,
      date: date ?? this.date,
      station: station ?? this.station,
      fuelType: fuelType ?? this.fuelType,
      fullTank: fullTank ?? this.fullTank,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() => 'FuelLog($gallons gal @ \$$pricePerGallon, $date)';
}

/// MPG calculation result
class MpgData {
  final double? averageMpg;
  final double? lastMpg;
  final double? bestMpg;
  final double? worstMpg;
  final int dataPoints;
  final String? message;

  MpgData({
    this.averageMpg,
    this.lastMpg,
    this.bestMpg,
    this.worstMpg,
    this.dataPoints = 0,
    this.message,
  });

  factory MpgData.fromJson(Map<String, dynamic> json) {
    return MpgData(
      averageMpg: json['average_mpg']?.toDouble(),
      lastMpg: json['last_mpg']?.toDouble(),
      bestMpg: json['best_mpg']?.toDouble(),
      worstMpg: json['worst_mpg']?.toDouble(),
      dataPoints: json['data_points'] ?? json['logs_used'] ?? 0,
      message: json['message'],
    );
  }

  bool get hasData => averageMpg != null;
}

/// Fuel cost summary
class FuelCostSummary {
  final int fillUps;
  final double totalGallons;
  final double totalCost;
  final double avgPricePerGallon;
  final int totalMiles;
  final double costPerMile;

  FuelCostSummary({
    required this.fillUps,
    required this.totalGallons,
    required this.totalCost,
    required this.avgPricePerGallon,
    required this.totalMiles,
    required this.costPerMile,
  });

  factory FuelCostSummary.fromJson(Map<String, dynamic> json) {
    return FuelCostSummary(
      fillUps: json['fill_ups'] ?? 0,
      totalGallons: (json['total_gallons'] ?? 0).toDouble(),
      totalCost: (json['total_cost'] ?? 0).toDouble(),
      avgPricePerGallon: (json['avg_price_per_gallon'] ?? 0).toDouble(),
      totalMiles: json['total_miles'] ?? 0,
      costPerMile: (json['cost_per_mile'] ?? 0).toDouble(),
    );
  }
}

/// Available fuel types
class FuelTypes {
  static const List<String> all = [
    'Regular',
    'Mid-Grade',
    'Premium',
    'Diesel',
    'E85',
    'Electric',
  ];
}

