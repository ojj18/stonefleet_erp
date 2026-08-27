class TransportMaintenanceModel {
  final int? id;
  final int transportVehicleId;
  final String? driverName;
  final double startingKm;
  final double closingKm;
  final double totalKm;
  final int numberOfLoads;
  final String? loadingSite;
  final String? unloadingSite;
  final double dieselFilled;
  final double dieselRate;
  final double dieselExpense;
  final String? remarks;
  final String createdAt;
  final String? updatedAt;

  const TransportMaintenanceModel({
    this.id,
    required this.transportVehicleId,
    this.driverName,
    required this.startingKm,
    required this.closingKm,
    required this.totalKm,
    this.numberOfLoads = 0,
    this.loadingSite,
    this.unloadingSite,
    this.dieselFilled = 0,
    this.dieselRate = 0,
    this.dieselExpense = 0,
    this.remarks,
    required this.createdAt,
    this.updatedAt,
  });

  factory TransportMaintenanceModel.fromMap(Map<String, dynamic> map) {
    return TransportMaintenanceModel(
      id: map['id'] as int?,
      transportVehicleId: map['transport_vehicle_id'] as int,
      driverName: map['driver_name'] as String?,
      startingKm: (map['starting_km'] as num).toDouble(),
      closingKm: (map['closing_km'] as num).toDouble(),
      totalKm: (map['total_km'] as num).toDouble(),
      numberOfLoads: map['number_of_loads'] as int? ?? 0,
      loadingSite: map['loading_site'] as String?,
      unloadingSite: map['unloading_site'] as String?,
      dieselFilled: (map['diesel_filled'] as num? ?? 0).toDouble(),
      dieselRate: (map['diesel_rate'] as num? ?? 0).toDouble(),
      dieselExpense: (map['diesel_expense'] as num? ?? 0).toDouble(),
      remarks: map['remarks'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transport_vehicle_id': transportVehicleId,
      'driver_name': driverName,
      'starting_km': startingKm,
      'closing_km': closingKm,
      'total_km': totalKm,
      'number_of_loads': numberOfLoads,
      'loading_site': loadingSite,
      'unloading_site': unloadingSite,
      'diesel_filled': dieselFilled,
      'diesel_rate': dieselRate,
      'diesel_expense': dieselExpense,
      'remarks': remarks,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  TransportMaintenanceModel copyWith({
    int? id,
    int? transportVehicleId,
    String? driverName,
    double? startingKm,
    double? closingKm,
    double? totalKm,
    int? numberOfLoads,
    String? loadingSite,
    String? unloadingSite,
    double? dieselFilled,
    double? dieselRate,
    double? dieselExpense,
    String? remarks,
    String? createdAt,
    String? updatedAt,
  }) {
    return TransportMaintenanceModel(
      id: id ?? this.id,
      transportVehicleId: transportVehicleId ?? this.transportVehicleId,
      driverName: driverName ?? this.driverName,
      startingKm: startingKm ?? this.startingKm,
      closingKm: closingKm ?? this.closingKm,
      totalKm: totalKm ?? this.totalKm,
      numberOfLoads: numberOfLoads ?? this.numberOfLoads,
      loadingSite: loadingSite ?? this.loadingSite,
      unloadingSite: unloadingSite ?? this.unloadingSite,
      dieselFilled: dieselFilled ?? this.dieselFilled,
      dieselRate: dieselRate ?? this.dieselRate,
      dieselExpense: dieselExpense ?? this.dieselExpense,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
