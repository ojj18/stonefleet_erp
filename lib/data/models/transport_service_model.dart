class TransportServiceModel {
  final int? id;
  final int transportVehicleId;
  final String serviceDate;
  final double currentKm;
  final String? remarks;
  final String createdAt;
  final String? updatedAt;

  const TransportServiceModel({
    this.id,
    required this.transportVehicleId,
    required this.serviceDate,
    required this.currentKm,
    this.remarks,
    required this.createdAt,
    this.updatedAt,
  });

  factory TransportServiceModel.fromMap(Map<String, dynamic> map) {
    return TransportServiceModel(
      id: map['id'] as int?,
      transportVehicleId: map['transport_vehicle_id'] as int,
      serviceDate: map['service_date'] as String,
      currentKm: (map['current_km'] as num).toDouble(),
      remarks: map['remarks'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transport_vehicle_id': transportVehicleId,
      'service_date': serviceDate,
      'current_km': currentKm,
      'remarks': remarks,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  TransportServiceModel copyWith({
    int? id,
    int? transportVehicleId,
    String? serviceDate,
    double? currentKm,
    String? remarks,
    String? createdAt,
    String? updatedAt,
  }) {
    return TransportServiceModel(
      id: id ?? this.id,
      transportVehicleId: transportVehicleId ?? this.transportVehicleId,
      serviceDate: serviceDate ?? this.serviceDate,
      currentKm: currentKm ?? this.currentKm,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
