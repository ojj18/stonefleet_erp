import '../models/service_notification_model.dart';
import '../repositories/service_notification_repository.dart';

class ServiceNotificationService {
  final ServiceNotificationRepository _repository;

  ServiceNotificationService({ServiceNotificationRepository? repository})
    : _repository = repository ?? ServiceNotificationRepository();

  Future<List<ServiceNotificationModel>> getNotifications() async {
    final excavatorRows = await _repository.getExcavatorNotificationData();

    final transportRows = await _repository.getTransportNotificationData();

    final notifications = <ServiceNotificationModel>[];

    notifications.addAll(_buildExcavatorNotifications(excavatorRows));

    notifications.addAll(_buildTransportNotifications(transportRows));

    return notifications;
  }

  List<ServiceNotificationModel> _buildExcavatorNotifications(
    List<Map<String, dynamic>> rows,
  ) {
    return rows.map((row) {
      return _buildNotification(
        row: row,
        isExcavator: true,
        currentMeter: _toDouble(row['current_meter']),
        lastServiceMeter: _toDouble(row['last_service_meter']),
        interval: _toDouble(row['interval_hours']) ?? 0,
        warning: _toDouble(row['warning_hours']) ?? 0,
      );
    }).toList();
  }

  List<ServiceNotificationModel> _buildTransportNotifications(
    List<Map<String, dynamic>> rows,
  ) {
    return rows.map((row) {
      return _buildNotification(
        row: row,
        isExcavator: false,
        currentMeter: _toDouble(row['current_meter']),
        lastServiceMeter: _toDouble(row['last_service_meter']),
        interval: _toDouble(row['interval_km']) ?? 0,
        warning: _toDouble(row['warning_km']) ?? 0,
      );
    }).toList();
  }

  ServiceNotificationModel _buildNotification({
    required Map<String, dynamic> row,
    required bool isExcavator,
    required double? currentMeter,
    required double? lastServiceMeter,
    required double interval,
    required double warning,
  }) {
    // No service history for this particular spare.
    if (lastServiceMeter == null) {
      return ServiceNotificationModel(
        equipmentId: row['equipment_id'] as int,
        registrationNumber: row['registration_number']?.toString() ?? '',
        modelName: row['model_name']?.toString(),
        spareId: row['spare_id'] as int,
        spareName: row['spare_name']?.toString() ?? '',
        isExcavator: isExcavator,
        currentMeter: currentMeter ?? 0,
        lastServiceMeter: null,
        interval: interval,
        warning: warning,
        nextServiceMeter: null,
        remaining: null,
        lastServiceDate: row['last_service_date']?.toString(),
        status: ServiceNotificationStatus.serviceNotRecorded,
      );
    }

    // Invalid schedule.
    if (interval <= 0) {
      return ServiceNotificationModel(
        equipmentId: row['equipment_id'] as int,
        registrationNumber: row['registration_number']?.toString() ?? '',
        modelName: row['model_name']?.toString(),
        spareId: row['spare_id'] as int,
        spareName: row['spare_name']?.toString() ?? '',
        isExcavator: isExcavator,
        currentMeter: currentMeter ?? lastServiceMeter,
        lastServiceMeter: lastServiceMeter,
        interval: interval,
        warning: warning,
        nextServiceMeter: null,
        remaining: null,
        lastServiceDate: row['last_service_date']?.toString(),
        status: ServiceNotificationStatus.normal,
      );
    }

    // If there is service history but no current meter,
    // use the last service reading as the known current reading.
    final effectiveCurrentMeter = currentMeter ?? lastServiceMeter;

    final nextServiceMeter = lastServiceMeter + interval;

    final remaining = nextServiceMeter - effectiveCurrentMeter;

    final status = _calculateStatus(remaining: remaining, warning: warning);

    return ServiceNotificationModel(
      equipmentId: row['equipment_id'] as int,
      registrationNumber: row['registration_number']?.toString() ?? '',
      modelName: row['model_name']?.toString(),
      spareId: row['spare_id'] as int,
      spareName: row['spare_name']?.toString() ?? '',
      isExcavator: isExcavator,
      currentMeter: effectiveCurrentMeter,
      lastServiceMeter: lastServiceMeter,
      interval: interval,
      warning: warning,
      nextServiceMeter: nextServiceMeter,
      remaining: remaining,
      lastServiceDate: row['last_service_date']?.toString(),
      status: status,
    );
  }

  ServiceNotificationStatus _calculateStatus({
    required double remaining,
    required double warning,
  }) {
    if (remaining < 0) {
      return ServiceNotificationStatus.overdue;
    }

    if (remaining == 0) {
      return ServiceNotificationStatus.due;
    }

    if (warning > 0 && remaining <= warning) {
      return ServiceNotificationStatus.upcoming;
    }

    return ServiceNotificationStatus.normal;
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString().replaceAll(',', '').trim());
  }
}
