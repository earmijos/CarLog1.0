/// Repair model for CarLog app.
class Repair {
  final int? id;
  final String vin;
  final String service;
  final String? description;
  final double cost;
  final int? mileage;
  final String date;
  final String? shopName;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  Repair({
    this.id,
    required this.vin,
    required this.service,
    this.description,
    required this.cost,
    this.mileage,
    required this.date,
    this.shopName,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Repair.fromJson(Map<String, dynamic> json) {
    return Repair(
      id: json['id'],
      vin: json['vin'] ?? '',
      service: json['service'] ?? '',
      description: json['description'],
      cost: (json['cost'] ?? 0).toDouble(),
      mileage: json['mileage'],
      date: json['date'] ?? '',
      shopName: json['shop_name'],
      notes: json['notes'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'vin': vin,
      'service': service,
      if (description != null) 'description': description,
      'cost': cost,
      if (mileage != null) 'mileage': mileage,
      'date': date,
      if (shopName != null) 'shop_name': shopName,
      if (notes != null) 'notes': notes,
    };
  }

  Repair copyWith({
    int? id,
    String? vin,
    String? service,
    String? description,
    double? cost,
    int? mileage,
    String? date,
    String? shopName,
    String? notes,
  }) {
    return Repair(
      id: id ?? this.id,
      vin: vin ?? this.vin,
      service: service ?? this.service,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      mileage: mileage ?? this.mileage,
      date: date ?? this.date,
      shopName: shopName ?? this.shopName,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() => 'Repair($service, \$$cost, $date)';
}

/// Repair cost summary by service type
class RepairCostSummary {
  final List<ServiceCost> byService;
  final double totalCost;
  final int repairCount;

  RepairCostSummary({
    required this.byService,
    required this.totalCost,
    required this.repairCount,
  });

  factory RepairCostSummary.fromJson(Map<String, dynamic> json) {
    return RepairCostSummary(
      byService: (json['by_service'] as List<dynamic>?)
              ?.map((s) => ServiceCost.fromJson(s))
              .toList() ??
          [],
      totalCost: (json['total_cost'] ?? 0).toDouble(),
      repairCount: json['repair_count'] ?? 0,
    );
  }
}

/// Cost breakdown for a single service type
class ServiceCost {
  final String service;
  final int count;
  final double totalCost;
  final double avgCost;
  final String? lastDate;

  ServiceCost({
    required this.service,
    required this.count,
    required this.totalCost,
    required this.avgCost,
    this.lastDate,
  });

  factory ServiceCost.fromJson(Map<String, dynamic> json) {
    return ServiceCost(
      service: json['service'] ?? '',
      count: json['count'] ?? 0,
      totalCost: (json['total_cost'] ?? 0).toDouble(),
      avgCost: (json['avg_cost'] ?? 0).toDouble(),
      lastDate: json['last_date'],
    );
  }
}

