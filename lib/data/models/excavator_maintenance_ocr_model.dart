class ExcavatorMaintenanceOcrModel {
  final String? registrationNumber;
  final String? operatorName;
  final String? shift;
  final double? startingHour;
  final double? closingHour;
  final double? bucketWorkingHour;
  final double? breakerWorkingHour;
  final int? numberOfLoads;
  final int? numberOfUnits;
  final double? dieselFilled;
  final double? dieselRate;
  final bool? teethSetChanged;
  final String? remarks;

  const ExcavatorMaintenanceOcrModel({
    this.registrationNumber,
    this.operatorName,
    this.shift,
    this.startingHour,
    this.closingHour,
    this.bucketWorkingHour,
    this.breakerWorkingHour,
    this.numberOfLoads,
    this.numberOfUnits,
    this.dieselFilled,
    this.dieselRate,
    this.teethSetChanged,
    this.remarks,
  });

  factory ExcavatorMaintenanceOcrModel.fromJson(Map<String, dynamic> json) {
    return ExcavatorMaintenanceOcrModel(
      registrationNumber: json['registration_number'] as String?,
      operatorName: json['operator_name'] as String?,
      shift: json['shift'] as String?,
      startingHour: _toDouble(json['starting_hour']),
      closingHour: _toDouble(json['closing_hour']),
      bucketWorkingHour: _toDouble(json['bucket_working_hour']),
      breakerWorkingHour: _toDouble(json['breaker_working_hour']),
      numberOfLoads: _toInt(json['number_of_loads']),
      numberOfUnits: _toInt(json['number_of_units']),
      dieselFilled: _toDouble(json['diesel_filled']),
      dieselRate: _toDouble(json['diesel_rate']),
      teethSetChanged: json['teeth_set_changed'] as bool?,
      remarks: json['remarks'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'registration_number': registrationNumber,
      'operator_name': operatorName,
      'shift': shift,
      'starting_hour': startingHour,
      'closing_hour': closingHour,
      'bucket_working_hour': bucketWorkingHour,
      'breaker_working_hour': breakerWorkingHour,
      'number_of_loads': numberOfLoads,
      'number_of_units': numberOfUnits,
      'diesel_filled': dieselFilled,
      'diesel_rate': dieselRate,
      'teeth_set_changed': teethSetChanged,
      'remarks': remarks,
    };
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
