class TransportMaintenanceOcrModel {
  final String? registrationNumber;
  final String? driverName;
  final double? startingKm;
  final double? closingKm;
  final int? numberOfLoads;
  final String? loadingSite;
  final String? unloadingSite;
  final double? dieselFilled;
  final double? dieselRate;
  final String? remarks;

  const TransportMaintenanceOcrModel({
    this.registrationNumber,
    this.driverName,
    this.startingKm,
    this.closingKm,
    this.numberOfLoads,
    this.loadingSite,
    this.unloadingSite,
    this.dieselFilled,
    this.dieselRate,
    this.remarks,
  });

  factory TransportMaintenanceOcrModel.fromJson(Map<String, dynamic> json) {
    return TransportMaintenanceOcrModel(
      registrationNumber: json['registration_number'] as String?,
      driverName: json['driver_name'] as String?,
      startingKm: _toDouble(json['starting_km']),
      closingKm: _toDouble(json['closing_km']),
      numberOfLoads: _toInt(json['number_of_loads']),
      loadingSite: json['loading_site'] as String?,
      unloadingSite: json['unloading_site'] as String?,
      dieselFilled: _toDouble(json['diesel_filled']),
      dieselRate: _toDouble(json['diesel_rate']),
      remarks: json['remarks'] as String?,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().replaceAll(',', '').trim());
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString().replaceAll(',', '').trim());
  }
}
