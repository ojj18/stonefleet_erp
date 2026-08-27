class ExcavatorServiceScheduleModel {
  final int? id;
  final int excavatorModelId;
  final int spareId;
  final double intervalHours;
  final double warningHours;
  final String createdAt;
  final String? updatedAt;

  const ExcavatorServiceScheduleModel({
    this.id,
    required this.excavatorModelId,
    required this.spareId,
    required this.intervalHours,
    this.warningHours = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory ExcavatorServiceScheduleModel.fromMap(Map<String, dynamic> map) {
    return ExcavatorServiceScheduleModel(
      id: map['id'] as int?,
      excavatorModelId: map['excavator_model_id'] as int,
      spareId: map['spare_id'] as int,
      intervalHours: (map['interval_hours'] as num).toDouble(),
      warningHours: (map['warning_hours'] as num? ?? 0).toDouble(),
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'excavator_model_id': excavatorModelId,
      'spare_id': spareId,
      'interval_hours': intervalHours,
      'warning_hours': warningHours,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  ExcavatorServiceScheduleModel copyWith({
    int? id,
    int? excavatorModelId,
    int? spareId,
    double? intervalHours,
    double? warningHours,
    String? createdAt,
    String? updatedAt,
  }) {
    return ExcavatorServiceScheduleModel(
      id: id ?? this.id,
      excavatorModelId: excavatorModelId ?? this.excavatorModelId,
      spareId: spareId ?? this.spareId,
      intervalHours: intervalHours ?? this.intervalHours,
      warningHours: warningHours ?? this.warningHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
