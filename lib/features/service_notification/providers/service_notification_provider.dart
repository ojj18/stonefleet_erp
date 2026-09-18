import 'package:flutter/foundation.dart';

import '../../../data/models/service_notification_model.dart';
import '../../../data/services/service_notification_service.dart';

class ServiceNotificationProvider extends ChangeNotifier {
  final ServiceNotificationService _service;

  ServiceNotificationProvider({ServiceNotificationService? service})
    : _service = service ?? ServiceNotificationService();

  // ============================================================
  // STATE
  // ============================================================

  List<ServiceNotificationModel> _notifications = [];

  bool _isLoading = false;

  String? _error;

  // ============================================================
  // GETTERS
  // ============================================================

  List<ServiceNotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  bool get isLoading => _isLoading;

  String? get error => _error;

  int get count => _notifications.length;

  int get overdueCount => _notifications
      .where((item) => item.status == ServiceNotificationStatus.overdue)
      .length;

  int get dueCount => _notifications
      .where((item) => item.status == ServiceNotificationStatus.due)
      .length;

  int get upcomingCount => _notifications
      .where((item) => item.status == ServiceNotificationStatus.upcoming)
      .length;

  int get serviceNotRecordedCount => _notifications
      .where(
        (item) => item.status == ServiceNotificationStatus.serviceNotRecorded,
      )
      .length;

  int get alertCount => overdueCount + dueCount + upcomingCount;

  // ============================================================
  // LOAD NOTIFICATIONS
  // ============================================================

  Future<void> loadNotifications() async {
    _setLoading(true);
    _clearError();

    try {
      _notifications = await _service.getNotifications();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refresh() async {
    await loadNotifications();
  }

  // ============================================================
  // FILTER HELPERS
  // ============================================================

  List<ServiceNotificationModel> get overdueNotifications => _notifications
      .where((item) => item.status == ServiceNotificationStatus.overdue)
      .toList();

  List<ServiceNotificationModel> get dueNotifications => _notifications
      .where((item) => item.status == ServiceNotificationStatus.due)
      .toList();

  List<ServiceNotificationModel> get upcomingNotifications => _notifications
      .where((item) => item.status == ServiceNotificationStatus.upcoming)
      .toList();

  List<ServiceNotificationModel> get serviceNotRecordedNotifications =>
      _notifications
          .where(
            (item) =>
                item.status == ServiceNotificationStatus.serviceNotRecorded,
          )
          .toList();

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _clearError();
  }

  void _clearError() {
    _error = null;
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
