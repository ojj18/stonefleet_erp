class TransportVehicleModel {
  final int? id;
  final String registrationNumber;
  final int manufacturerId;
  final int modelId;
  final int? manufacturingYear;
  final String? emissionStandard;
  final bool status;
  final String? insuranceExpiry;
  final String? fcExpiry;
  final String? permitExpiry;
  final String? taxExpiry;
  final String createdAt;
  final String? updatedAt;

  const TransportVehicleModel({
    this.id,
    required this.registrationNumber,
    required this.manufacturerId,
    required this.modelId,
    this.manufacturingYear,
    this.emissionStandard,
    this.status = true,
    this.insuranceExpiry,
    this.fcExpiry,
    this.permitExpiry,
    this.taxExpiry,
    required this.createdAt,
    this.updatedAt,
  });

  factory TransportVehicleModel.fromMap(Map<String, dynamic> map) {
    return TransportVehicleModel(
      id: map['id'] as int?,
      registrationNumber: map['registration_number'] as String,
      manufacturerId: map['manufacturer_id'] as int,
      modelId: map['model_id'] as int,
      manufacturingYear: map['manufacturing_year'] as int?,
      emissionStandard: map['emission_standard'] as String?,
      status: (map['status'] as int? ?? 1) == 1,
      insuranceExpiry: map['insurance_expiry'] as String?,
      fcExpiry: map['fc_expiry'] as String?,
      permitExpiry: map['permit_expiry'] as String?,
      taxExpiry: map['tax_expiry'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'registration_number': registrationNumber,
      'manufacturer_id': manufacturerId,
      'model_id': modelId,
      'manufacturing_year': manufacturingYear,
      'emission_standard': emissionStandard,
      'status': status ? 1 : 0,
      'insurance_expiry': insuranceExpiry,
      'fc_expiry': fcExpiry,
      'permit_expiry': permitExpiry,
      'tax_expiry': taxExpiry,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  TransportVehicleModel copyWith({
    int? id,
    String? registrationNumber,
    int? manufacturerId,
    int? modelId,
    int? manufacturingYear,
    String? emissionStandard,
    bool? status,
    String? insuranceExpiry,
    String? fcExpiry,
    String? permitExpiry,
    String? taxExpiry,
    String? createdAt,
    String? updatedAt,
  }) {
    return TransportVehicleModel(
      id: id ?? this.id,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      manufacturerId: manufacturerId ?? this.manufacturerId,
      modelId: modelId ?? this.modelId,
      manufacturingYear: manufacturingYear ?? this.manufacturingYear,
      emissionStandard: emissionStandard ?? this.emissionStandard,
      status: status ?? this.status,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      fcExpiry: fcExpiry ?? this.fcExpiry,
      permitExpiry: permitExpiry ?? this.permitExpiry,
      taxExpiry: taxExpiry ?? this.taxExpiry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
