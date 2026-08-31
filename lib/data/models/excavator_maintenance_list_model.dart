class ExcavatorMaintenanceListModel {
  final int? id;

  final int excavatorId;
  final String registrationNumber;

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

  const ExcavatorMaintenanceListModel({
    this.id,
    required this.excavatorId,
    required this.registrationNumber,
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

  factory ExcavatorMaintenanceListModel.fromMap(Map<String, dynamic> map) {
    return ExcavatorMaintenanceListModel(
      id: map['id'] as int?,

      excavatorId: (map['excavator_id'] as num).toInt(),

      registrationNumber: map['registration_number'] as String? ?? '',

      operatorName: map['operator_name'] as String?,

      shift: map['shift'] as String?,

      startingHour: (map['starting_hour'] as num).toDouble(),

      closingHour: (map['closing_hour'] as num).toDouble(),

      totalWorkingHour: (map['total_working_hour'] as num).toDouble(),

      bucketWorkingHour: (map['bucket_working_hour'] as num? ?? 0).toDouble(),

      breakerWorkingHour: (map['breaker_working_hour'] as num? ?? 0).toDouble(),

      totalRunningHour: (map['total_running_hour'] as num).toDouble(),

      numberOfLoads: (map['number_of_loads'] as num? ?? 0).toInt(),

      units: (map['units'] as num? ?? 0).toDouble(),

      dieselFilled: (map['diesel_filled'] as num? ?? 0).toDouble(),

      dieselRate: (map['diesel_rate'] as num? ?? 0).toDouble(),

      dieselExpense: (map['diesel_expense'] as num? ?? 0).toDouble(),

      dieselExpensePerHour: (map['diesel_expense_per_hour'] as num? ?? 0)
          .toDouble(),

      teethSetChanged: (map['teeth_set_changed'] as num? ?? 0).toInt() == 1,

      remarks: map['remarks'] as String?,

      createdAt: map['created_at'] as String,

      updatedAt: map['updated_at'] as String?,
    );
  }
}
