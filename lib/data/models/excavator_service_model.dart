class ExcavatorServiceModel {
  final int? id;
  final int excavatorId;
  final String serviceDate;
  final double currentHourMeter;
  final String? remarks;
  final String createdAt;
  final String? updatedAt;

  const ExcavatorServiceModel({
    this.id,
    required this.excavatorId,
    required this.serviceDate,
    required this.currentHourMeter,
    this.remarks,
    required this.createdAt,
    this.updatedAt,
  });

  factory ExcavatorServiceModel.fromMap(Map<String, dynamic> map) {
    return ExcavatorServiceModel(
      id: map['id'] as int?,
      excavatorId: map['excavator_id'] as int,
      serviceDate: map['service_date'] as String,
      currentHourMeter: (map['current_hour_meter'] as num).toDouble(),
      remarks: map['remarks'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'excavator_id': excavatorId,
      'service_date': serviceDate,
      'current_hour_meter': currentHourMeter,
      'remarks': remarks,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  ExcavatorServiceModel copyWith({
    int? id,
    int? excavatorId,
    String? serviceDate,
    double? currentHourMeter,
    String? remarks,
    String? createdAt,
    String? updatedAt,
  }) {
    return ExcavatorServiceModel(
      id: id ?? this.id,
      excavatorId: excavatorId ?? this.excavatorId,
      serviceDate: serviceDate ?? this.serviceDate,
      currentHourMeter: currentHourMeter ?? this.currentHourMeter,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
