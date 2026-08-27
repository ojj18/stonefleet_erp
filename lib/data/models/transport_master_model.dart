class TransportModel {
  final int? id;
  final int manufacturerId;
  final String modelName;
  final String? modelCode;
  final String vehicleType;
  final bool isActive;
  final String createdAt;
  final String? updatedAt;

  const TransportModel({
    this.id,
    required this.manufacturerId,
    required this.modelName,
    this.modelCode,
    required this.vehicleType,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory TransportModel.fromMap(Map<String, dynamic> map) {
    return TransportModel(
      id: map['id'] as int?,
      manufacturerId: map['manufacturer_id'] as int,
      modelName: map['model_name'] as String,
      modelCode: map['model_code'] as String?,
      vehicleType: map['vehicle_type'] as String,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'manufacturer_id': manufacturerId,
      'model_name': modelName,
      'model_code': modelCode,
      'vehicle_type': vehicleType,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  TransportModel copyWith({
    int? id,
    int? manufacturerId,
    String? modelName,
    String? modelCode,
    String? vehicleType,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return TransportModel(
      id: id ?? this.id,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      modelName: modelName ?? this.modelName,
      modelCode: modelCode ?? this.modelCode,
      vehicleType: vehicleType ?? this.vehicleType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
