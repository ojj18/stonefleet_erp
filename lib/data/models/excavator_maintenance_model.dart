class ExcavatorMaintenanceModel {
  final int? id;
  final int excavatorId;
  final String? operatorName;
  final String? shift;
  final double startingHour;
  final double closingHour;
  final double totalWorkingHour;
  final double bucketWorkingHour;
  final double breakerWorkingHour;
  final double totalRunningHour;
  final int numberOfLoads;
  final double units;
  final double dieselFilled;
  final double dieselRate;
  final double dieselExpense;
  final double dieselExpensePerHour;
  final bool teethSetChanged;
  final String? remarks;
  final String createdAt;
  final String? updatedAt;

  const ExcavatorMaintenanceModel({
    this.id,
    required this.excavatorId,
    this.operatorName,
    this.shift,
    required this.startingHour,
    required this.closingHour,
    required this.totalWorkingHour,
    this.bucketWorkingHour = 0,
    this.breakerWorkingHour = 0,
    required this.totalRunningHour,
    this.numberOfLoads = 0,
    this.units = 0,
    this.dieselFilled = 0,
    this.dieselRate = 0,
    this.dieselExpense = 0,
    this.dieselExpensePerHour = 0,
    this.teethSetChanged = false,
    this.remarks,
    required this.createdAt,
    this.updatedAt,
  });

  factory ExcavatorMaintenanceModel.fromMap(Map<String, dynamic> map) {
    return ExcavatorMaintenanceModel(
      id: map['id'] as int?,
      excavatorId: map['excavator_id'] as int,
      operatorName: map['operator_name'] as String?,
      shift: map['shift'] as String?,
      startingHour: (map['starting_hour'] as num).toDouble(),
      closingHour: (map['closing_hour'] as num).toDouble(),
      totalWorkingHour: (map['total_working_hour'] as num).toDouble(),
      bucketWorkingHour: (map['bucket_working_hour'] as num? ?? 0).toDouble(),
      breakerWorkingHour: (map['breaker_working_hour'] as num? ?? 0).toDouble(),
      totalRunningHour: (map['total_running_hour'] as num).toDouble(),
      numberOfLoads: map['number_of_loads'] as int? ?? 0,
      units: (map['units'] as num? ?? 0).toDouble(),
      dieselFilled: (map['diesel_filled'] as num? ?? 0).toDouble(),
      dieselRate: (map['diesel_rate'] as num? ?? 0).toDouble(),
      dieselExpense: (map['diesel_expense'] as num? ?? 0).toDouble(),
      dieselExpensePerHour: (map['diesel_expense_per_hour'] as num? ?? 0)
          .toDouble(),
      teethSetChanged: (map['teeth_set_changed'] as int? ?? 0) == 1,
      remarks: map['remarks'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'excavator_id': excavatorId,
      'operator_name': operatorName,
      'shift': shift,
      'starting_hour': startingHour,
      'closing_hour': closingHour,
      'total_working_hour': totalWorkingHour,
      'bucket_working_hour': bucketWorkingHour,
      'breaker_working_hour': breakerWorkingHour,
      'total_running_hour': totalRunningHour,
      'number_of_loads': numberOfLoads,
      'units': units,
      'diesel_filled': dieselFilled,
      'diesel_rate': dieselRate,
      'diesel_expense': dieselExpense,
      'diesel_expense_per_hour': dieselExpensePerHour,
      'teeth_set_changed': teethSetChanged ? 1 : 0,
      'remarks': remarks,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  ExcavatorMaintenanceModel copyWith({
    int? id,
    int? excavatorId,
    String? operatorName,
    String? shift,
    double? startingHour,
    double? closingHour,
    double? totalWorkingHour,
    double? bucketWorkingHour,
    double? breakerWorkingHour,
    double? totalRunningHour,
    int? numberOfLoads,
    double? units,
    double? dieselFilled,
    double? dieselRate,
    double? dieselExpense,
    double? dieselExpensePerHour,
    bool? teethSetChanged,
    String? remarks,
    String? createdAt,
    String? updatedAt,
  }) {
    return ExcavatorMaintenanceModel(
      id: id ?? this.id,
      excavatorId: excavatorId ?? this.excavatorId,
      operatorName: operatorName ?? this.operatorName,
      shift: shift ?? this.shift,
      startingHour: startingHour ?? this.startingHour,
      closingHour: closingHour ?? this.closingHour,
      totalWorkingHour: totalWorkingHour ?? this.totalWorkingHour,
      bucketWorkingHour: bucketWorkingHour ?? this.bucketWorkingHour,
      breakerWorkingHour: breakerWorkingHour ?? this.breakerWorkingHour,
      totalRunningHour: totalRunningHour ?? this.totalRunningHour,
      numberOfLoads: numberOfLoads ?? this.numberOfLoads,
      units: units ?? this.units,
      dieselFilled: dieselFilled ?? this.dieselFilled,
      dieselRate: dieselRate ?? this.dieselRate,
      dieselExpense: dieselExpense ?? this.dieselExpense,
      dieselExpensePerHour: dieselExpensePerHour ?? this.dieselExpensePerHour,
      teethSetChanged: teethSetChanged ?? this.teethSetChanged,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
