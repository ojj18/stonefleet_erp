class TransportServiceScheduleModel {
  final int? id;
  final int transportModelId;
  final int spareId;
  final double intervalKm;
  final double warningKm;
  final String createdAt;
  final String? updatedAt;

  const TransportServiceScheduleModel({
    this.id,
    required this.transportModelId,
    required this.spareId,
    required this.intervalKm,
    this.warningKm = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory TransportServiceScheduleModel.fromMap(Map<String, dynamic> map) {
    return TransportServiceScheduleModel(
      id: map['id'] as int?,
      transportModelId: map['transport_model_id'] as int,
      spareId: map['spare_id'] as int,
      intervalKm: (map['interval_km'] as num).toDouble(),
      warningKm: (map['warning_km'] as num? ?? 0).toDouble(),
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transport_model_id': transportModelId,
      'spare_id': spareId,
      'interval_km': intervalKm,
      'warning_km': warningKm,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  TransportServiceScheduleModel copyWith({
    int? id,
    int? transportModelId,
    int? spareId,
    double? intervalKm,
    double? warningKm,
    String? createdAt,
    String? updatedAt,
  }) {
    return TransportServiceScheduleModel(
      id: id ?? this.id,
      transportModelId: transportModelId ?? this.transportModelId,
      spareId: spareId ?? this.spareId,
      intervalKm: intervalKm ?? this.intervalKm,
      warningKm: warningKm ?? this.warningKm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
