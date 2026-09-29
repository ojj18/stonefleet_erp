class VehicleRcModel {
  final String registrationNumber;
  final String? registrationDate;
  final String? rcStatus;

  final String? manufacturer;
  final String? model;
  final String? manufacturingDate;

  final String? vehicleCategory;
  final String? vehicleCategoryDescription;
  final String? fuelType;
  final String? color;

  final String? fitnessExpiry;
  final String? insuranceExpiry;
  final String? taxExpiry;
  final String? permitExpiry;

  final String? insuranceCompany;
  final String? permitNumber;
  final String? permitType;

  const VehicleRcModel({
    required this.registrationNumber,
    this.registrationDate,
    this.rcStatus,
    this.manufacturer,
    this.model,
    this.manufacturingDate,
    this.vehicleCategory,
    this.vehicleCategoryDescription,
    this.fuelType,
    this.color,
    this.fitnessExpiry,
    this.insuranceExpiry,
    this.taxExpiry,
    this.permitExpiry,
    this.insuranceCompany,
    this.permitNumber,
    this.permitType,
  });

  factory VehicleRcModel.fromJson(Map<String, dynamic> json) {
    return VehicleRcModel(
      registrationNumber: _string(json['rc_number']) ?? '',

      registrationDate: _string(json['registration_date']),

      rcStatus: _string(json['rc_status']),

      manufacturer: _string(json['maker_description']),

      model: _string(json['maker_model']),

      manufacturingDate: _string(
        json['manufacturing_date_formatted'] ?? json['manufacturing_date'],
      ),

      vehicleCategory: _string(json['vehicle_category']),

      vehicleCategoryDescription: _string(json['vehicle_category_description']),

      fuelType: _string(json['fuel_type']),

      color: _string(json['color']),

      fitnessExpiry: _string(json['fit_up_to']),

      insuranceExpiry: _string(json['insurance_upto']),

      taxExpiry: _string(json['tax_upto']),

      permitExpiry: _string(json['permit_valid_upto']),

      insuranceCompany: _string(json['insurance_company']),

      permitNumber: _string(json['permit_number']),

      permitType: _string(json['permit_type']),
    );
  }

  static String? _string(dynamic value) {
    if (value == null) return null;

    final valueString = value.toString().trim();

    if (valueString.isEmpty) return null;

    return valueString;
  }
}
