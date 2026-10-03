class TransportModel {
  final int? id;

  final String registrationNumber;

  final String? manufacturerName;
  final String? modelName;
  final int? manufacturingYear;

  final String? ownerName;
  final String? permanentAddress;
  final String? vehicleChasiNumber;
  final String? vehicleEngineNumber;
  final String? color;
  final String? insuranceCompany;

  final String? emissionStandard;
  final double unit;

  final String? insuranceExpiry;
  final String? fcExpiry;
  final String? permitExpiry;
  final String? taxExpiry;

  final bool status;

  final String createdAt;
  final String? updatedAt;

  const TransportModel({
    this.id,
    required this.registrationNumber,
    this.manufacturerName,
    this.modelName,
    this.manufacturingYear,
    this.ownerName,
    this.permanentAddress,
    this.vehicleChasiNumber,
    this.vehicleEngineNumber,
    this.color,
    this.insuranceCompany,
    this.emissionStandard,
    this.unit = 0,
    this.insuranceExpiry,
    this.fcExpiry,
    this.permitExpiry,
    this.taxExpiry,
    this.status = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory TransportModel.fromMap(Map<String, dynamic> map) {
    return TransportModel(
      id: map['id'] as int?,
      registrationNumber: map['registration_number'] as String,
      manufacturerName: map['manufacturer_name'] as String?,
      modelName: map['model_name'] as String?,
      manufacturingYear: map['manufacturing_year'] as int?,
      ownerName: map['owner_name'] as String?,
      permanentAddress: map['permanent_address'] as String?,
      vehicleChasiNumber: map['vehicle_chasi_number'] as String?,
      vehicleEngineNumber: map['vehicle_engine_number'] as String?,
      color: map['color'] as String?,
      insuranceCompany: map['insurance_company'] as String?,
      emissionStandard: map['emission_standard'] as String?,
      unit: (map['unit'] as num?)?.toDouble() ?? 0,
      insuranceExpiry: map['insurance_expiry'] as String?,
      fcExpiry: map['fc_expiry'] as String?,
      permitExpiry: map['permit_expiry'] as String?,
      taxExpiry: map['tax_expiry'] as String?,
      status: (map['status'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'registration_number': registrationNumber,
      'manufacturer_name': manufacturerName,
      'model_name': modelName,
      'manufacturing_year': manufacturingYear,
      'owner_name': ownerName,
      'permanent_address': permanentAddress,
      'vehicle_chasi_number': vehicleChasiNumber,
      'vehicle_engine_number': vehicleEngineNumber,
      'color': color,
      'insurance_company': insuranceCompany,
      'emission_standard': emissionStandard,
      'unit': unit,
      'insurance_expiry': insuranceExpiry,
      'fc_expiry': fcExpiry,
      'permit_expiry': permitExpiry,
      'tax_expiry': taxExpiry,
      'status': status ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  TransportModel copyWith({
    int? id,
    String? registrationNumber,
    String? manufacturerName,
    String? modelName,
    int? manufacturingYear,
    String? ownerName,
    String? permanentAddress,
    String? vehicleChasiNumber,
    String? vehicleEngineNumber,
    String? color,
    String? insuranceCompany,
    String? emissionStandard,
    double? unit,
    String? insuranceExpiry,
    String? fcExpiry,
    String? permitExpiry,
    String? taxExpiry,
    bool? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return TransportModel(
      id: id ?? this.id,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      modelName: modelName ?? this.modelName,
      manufacturingYear: manufacturingYear ?? this.manufacturingYear,
      ownerName: ownerName ?? this.ownerName,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      vehicleChasiNumber: vehicleChasiNumber ?? this.vehicleChasiNumber,
      vehicleEngineNumber: vehicleEngineNumber ?? this.vehicleEngineNumber,
      color: color ?? this.color,
      insuranceCompany: insuranceCompany ?? this.insuranceCompany,
      emissionStandard: emissionStandard ?? this.emissionStandard,
      unit: unit ?? this.unit,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      fcExpiry: fcExpiry ?? this.fcExpiry,
      permitExpiry: permitExpiry ?? this.permitExpiry,
      taxExpiry: taxExpiry ?? this.taxExpiry,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
