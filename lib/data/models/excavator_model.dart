class ExcavatorModel {
  final int? id;

  // Vehicle details
  final String registrationNumber;
  final String? manufacturerName;
  final String? modelName;
  final int? manufacturingYear;

  // Document expiry
  final String? insuranceExpiry;
  final String? fcExpiry;
  final String? permitExpiry;
  final String? taxExpiry;

  // Status
  final bool status;

  // Audit
  final String createdAt;
  final String? updatedAt;

  const ExcavatorModel({
    this.id,
    required this.registrationNumber,
    this.manufacturerName,
    this.modelName,
    this.manufacturingYear,
    this.insuranceExpiry,
    this.fcExpiry,
    this.permitExpiry,
    this.taxExpiry,
    this.status = true,
    required this.createdAt,
    this.updatedAt,
  });

  // ------------------------------------------------------------
  // FROM MAP
  // ------------------------------------------------------------

  factory ExcavatorModel.fromMap(Map<String, dynamic> map) {
    return ExcavatorModel(
      id: map['id'] as int?,
      registrationNumber: map['registration_number'] as String,
      manufacturerName: map['manufacturer_name'] as String?,
      modelName: map['model_name'] as String?,
      manufacturingYear: map['manufacturing_year'] as int?,
      insuranceExpiry: map['insurance_expiry'] as String?,
      fcExpiry: map['fc_expiry'] as String?,
      permitExpiry: map['permit_expiry'] as String?,
      taxExpiry: map['tax_expiry'] as String?,
      status: (map['status'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  // ------------------------------------------------------------
  // TO MAP
  // ------------------------------------------------------------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'registration_number': registrationNumber,
      'manufacturer_name': manufacturerName,
      'model_name': modelName,
      'manufacturing_year': manufacturingYear,
      'insurance_expiry': insuranceExpiry,
      'fc_expiry': fcExpiry,
      'permit_expiry': permitExpiry,
      'tax_expiry': taxExpiry,
      'status': status ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  // ------------------------------------------------------------
  // COPY WITH
  // ------------------------------------------------------------

  ExcavatorModel copyWith({
    int? id,
    String? registrationNumber,
    String? manufacturerName,
    String? modelName,
    int? manufacturingYear,
    String? insuranceExpiry,
    String? fcExpiry,
    String? permitExpiry,
    String? taxExpiry,
    bool? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return ExcavatorModel(
      id: id ?? this.id,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      manufacturerName: manufacturerName ?? this.manufacturerName,
      modelName: modelName ?? this.modelName,
      manufacturingYear: manufacturingYear ?? this.manufacturingYear,
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
