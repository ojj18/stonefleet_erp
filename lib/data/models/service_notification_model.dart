enum ServiceNotificationStatus {
  normal,
  upcoming,
  due,
  overdue,
  serviceNotRecorded,
}

class ServiceNotificationModel {
  final int equipmentId;
  final String registrationNumber;
  final String? modelName;

  final int spareId;
  final String spareName;

  final bool isExcavator;

  final double currentMeter;
  final double? lastServiceMeter;

  final double interval;
  final double warning;

  final double? nextServiceMeter;
  final double? remaining;

  final String? lastServiceDate;

  final ServiceNotificationStatus status;

  const ServiceNotificationModel({
    required this.equipmentId,
    required this.registrationNumber,
    this.modelName,
    required this.spareId,
    required this.spareName,
    required this.isExcavator,
    required this.currentMeter,
    this.lastServiceMeter,
    required this.interval,
    required this.warning,
    this.nextServiceMeter,
    this.remaining,
    this.lastServiceDate,
    required this.status,
  });

  String get meterUnit => isExcavator ? 'Hours' : 'KM';

  String get statusText {
    switch (status) {
      case ServiceNotificationStatus.normal:
        return 'Normal';

      case ServiceNotificationStatus.upcoming:
        return 'Upcoming';

      case ServiceNotificationStatus.due:
        return 'Due';

      case ServiceNotificationStatus.overdue:
        return 'Overdue';

      case ServiceNotificationStatus.serviceNotRecorded:
        return 'Service Not Recorded';
    }
  }

  ServiceNotificationModel copyWith({
    int? equipmentId,
    String? registrationNumber,
    String? modelName,
    int? spareId,
    String? spareName,
    bool? isExcavator,
    double? currentMeter,
    double? lastServiceMeter,
    double? interval,
    double? warning,
    double? nextServiceMeter,
    double? remaining,
    String? lastServiceDate,
    ServiceNotificationStatus? status,
  }) {
    return ServiceNotificationModel(
      equipmentId: equipmentId ?? this.equipmentId,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      modelName: modelName ?? this.modelName,
      spareId: spareId ?? this.spareId,
      spareName: spareName ?? this.spareName,
      isExcavator: isExcavator ?? this.isExcavator,
      currentMeter: currentMeter ?? this.currentMeter,
      lastServiceMeter: lastServiceMeter ?? this.lastServiceMeter,
      interval: interval ?? this.interval,
      warning: warning ?? this.warning,
      nextServiceMeter: nextServiceMeter ?? this.nextServiceMeter,
      remaining: remaining ?? this.remaining,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      status: status ?? this.status,
    );
  }
}
