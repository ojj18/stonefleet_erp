import 'package:flutter/foundation.dart';

import '../../../data/models/dashboard_model.dart';
import '../../../data/repositories/dashboard_repository.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _repository;

  DashboardProvider({DashboardRepository? repository})
    : _repository = repository ?? DashboardRepository();

  DashboardModel? _dashboard;

  bool _isLoading = false;
  String? _error;

  // ============================================================
  // GETTERS
  // ============================================================

  DashboardModel? get dashboard => _dashboard;

  bool get isLoading => _isLoading;

  String? get error => _error;

  // ============================================================
  // LOAD DASHBOARD
  // ============================================================

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;

    notifyListeners();

    try {
      _dashboard = await _repository.getDashboard();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refreshDashboard() async {
    await loadDashboard();
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _error = null;

    notifyListeners();
  }
}
