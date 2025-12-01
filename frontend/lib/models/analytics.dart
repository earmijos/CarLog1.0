import 'fuel_log.dart';

/// Dashboard data for a vehicle
class VehicleDashboard {
  final Map<String, dynamic> vehicle;
  final int currentMileage;
  final RepairStats repairs;
  final FuelStats fuel;
  final TripStats trips;
  final MpgData mpg;
  final List<MaintenanceAlert> upcomingMaintenance;
  final List<MaintenanceAlert> overdueMaintenance;
  final double totalCost;

  VehicleDashboard({
    required this.vehicle,
    required this.currentMileage,
    required this.repairs,
    required this.fuel,
    required this.trips,
    required this.mpg,
    required this.upcomingMaintenance,
    required this.overdueMaintenance,
    required this.totalCost,
  });

  factory VehicleDashboard.fromJson(Map<String, dynamic> json) {
    return VehicleDashboard(
      vehicle: json['vehicle'] ?? {},
      currentMileage: json['current_mileage'] ?? 0,
      repairs: RepairStats.fromJson(json['repairs'] ?? {}),
      fuel: FuelStats.fromJson(json['fuel'] ?? {}),
      trips: TripStats.fromJson(json['trips'] ?? {}),
      mpg: MpgData.fromJson(json['mpg'] ?? {}),
      upcomingMaintenance: (json['upcoming_maintenance'] as List<dynamic>?)
              ?.map((m) => MaintenanceAlert.fromJson(m))
              .toList() ??
          [],
      overdueMaintenance: (json['overdue_maintenance'] as List<dynamic>?)
              ?.map((m) => MaintenanceAlert.fromJson(m))
              .toList() ??
          [],
      totalCost: (json['total_cost'] ?? 0).toDouble(),
    );
  }

  /// Get vehicle display name
  String get vehicleDisplayName {
    final year = vehicle['year'] ?? '';
    final make = vehicle['make'] ?? '';
    final model = vehicle['model'] ?? '';
    return '$year $make $model'.trim();
  }
}

/// Repair statistics
class RepairStats {
  final int count;
  final double totalCost;
  final String? lastRepairDate;

  RepairStats({
    required this.count,
    required this.totalCost,
    this.lastRepairDate,
  });

  factory RepairStats.fromJson(Map<String, dynamic> json) {
    return RepairStats(
      count: json['count'] ?? 0,
      totalCost: (json['total_cost'] ?? 0).toDouble(),
      lastRepairDate: json['last_repair_date'],
    );
  }
}

/// Fuel statistics
class FuelStats {
  final int fillUps;
  final double totalCost;
  final double totalGallons;

  FuelStats({
    required this.fillUps,
    required this.totalCost,
    required this.totalGallons,
  });

  factory FuelStats.fromJson(Map<String, dynamic> json) {
    return FuelStats(
      fillUps: json['fill_ups'] ?? 0,
      totalCost: (json['total_cost'] ?? 0).toDouble(),
      totalGallons: (json['total_gallons'] ?? 0).toDouble(),
    );
  }
}

/// Trip statistics
class TripStats {
  final int count;
  final double totalMiles;
  final double businessMiles;

  TripStats({
    required this.count,
    required this.totalMiles,
    required this.businessMiles,
  });

  factory TripStats.fromJson(Map<String, dynamic> json) {
    return TripStats(
      count: json['count'] ?? 0,
      totalMiles: (json['total_miles'] ?? 0).toDouble(),
      businessMiles: (json['business_miles'] ?? 0).toDouble(),
    );
  }
}

/// Maintenance alert item
class MaintenanceAlert {
  final String serviceType;
  final int? nextDueMileage;

  MaintenanceAlert({
    required this.serviceType,
    this.nextDueMileage,
  });

  factory MaintenanceAlert.fromJson(Map<String, dynamic> json) {
    return MaintenanceAlert(
      serviceType: json['service_type'] ?? '',
      nextDueMileage: json['next_due_mileage'],
    );
  }
}

/// Cost per mile statistics
class CostPerMileData {
  final double totalCost;
  final double repairCost;
  final double fuelCost;
  final int totalMiles;
  final double costPerMile;
  final double fuelCostPerMile;
  final double repairCostPerMile;

  CostPerMileData({
    required this.totalCost,
    required this.repairCost,
    required this.fuelCost,
    required this.totalMiles,
    required this.costPerMile,
    required this.fuelCostPerMile,
    required this.repairCostPerMile,
  });

  factory CostPerMileData.fromJson(Map<String, dynamic> json) {
    return CostPerMileData(
      totalCost: (json['total_cost'] ?? 0).toDouble(),
      repairCost: (json['repair_cost'] ?? 0).toDouble(),
      fuelCost: (json['fuel_cost'] ?? 0).toDouble(),
      totalMiles: json['total_miles'] ?? 0,
      costPerMile: (json['cost_per_mile'] ?? 0).toDouble(),
      fuelCostPerMile: (json['fuel_cost_per_mile'] ?? 0).toDouble(),
      repairCostPerMile: (json['repair_cost_per_mile'] ?? 0).toDouble(),
    );
  }
}

/// Monthly spending data
class MonthlySpending {
  final String month;
  final double repairs;
  final double fuel;
  final double total;

  MonthlySpending({
    required this.month,
    required this.repairs,
    required this.fuel,
    required this.total,
  });

  factory MonthlySpending.fromJson(Map<String, dynamic> json) {
    return MonthlySpending(
      month: json['month'] ?? '',
      repairs: (json['repairs'] ?? 0).toDouble(),
      fuel: (json['fuel'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
    );
  }

  /// Get display month (e.g., "2024-01" -> "Jan")
  String get displayMonth {
    try {
      final monthNum = int.parse(month.split('-')[1]);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return months[monthNum - 1];
    } catch (_) {
      return month;
    }
  }
}

/// Spending by category
class CategorySpending {
  final String category;
  final int count;
  final double totalCost;
  final double avgCost;

  CategorySpending({
    required this.category,
    required this.count,
    required this.totalCost,
    required this.avgCost,
  });

  factory CategorySpending.fromJson(Map<String, dynamic> json) {
    return CategorySpending(
      category: json['category'] ?? '',
      count: json['count'] ?? 0,
      totalCost: (json['total_cost'] ?? 0).toDouble(),
      avgCost: (json['avg_cost'] ?? 0).toDouble(),
    );
  }
}

/// Fuel price trend data
class FuelPriceTrend {
  final String month;
  final double avgPrice;
  final double minPrice;
  final double maxPrice;
  final double totalGallons;
  final double totalCost;

  FuelPriceTrend({
    required this.month,
    required this.avgPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.totalGallons,
    required this.totalCost,
  });

  factory FuelPriceTrend.fromJson(Map<String, dynamic> json) {
    return FuelPriceTrend(
      month: json['month'] ?? '',
      avgPrice: (json['avg_price'] ?? 0).toDouble(),
      minPrice: (json['min_price'] ?? 0).toDouble(),
      maxPrice: (json['max_price'] ?? 0).toDouble(),
      totalGallons: (json['total_gallons'] ?? 0).toDouble(),
      totalCost: (json['total_cost'] ?? 0).toDouble(),
    );
  }
}

/// All vehicles summary item
class VehicleSummaryItem {
  final String vin;
  final int year;
  final String make;
  final String model;
  final String displayName;
  final int currentMileage;
  final double repairCost;
  final double fuelCost;
  final double totalCost;
  final int repairCount;

  VehicleSummaryItem({
    required this.vin,
    required this.year,
    required this.make,
    required this.model,
    required this.displayName,
    required this.currentMileage,
    required this.repairCost,
    required this.fuelCost,
    required this.totalCost,
    required this.repairCount,
  });

  factory VehicleSummaryItem.fromJson(Map<String, dynamic> json) {
    return VehicleSummaryItem(
      vin: json['vin'] ?? '',
      year: json['year'] ?? 0,
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      displayName: json['display_name'] ?? '',
      currentMileage: json['current_mileage'] ?? 0,
      repairCost: (json['repair_cost'] ?? 0).toDouble(),
      fuelCost: (json['fuel_cost'] ?? 0).toDouble(),
      totalCost: (json['total_cost'] ?? 0).toDouble(),
      repairCount: json['repair_count'] ?? 0,
    );
  }
}

