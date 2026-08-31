import 'package:flutter/foundation.dart';

import '../../../../data/models/transport_maintenance_model.dart';
import '../../../../data/repositories/transport_maintenance_repository.dart';

class TransportMaintenanceProvider extends ChangeNotifier {
  final TransportMaintenanceRepository _repository;

  TransportMaintenanceProvider({TransportMaintenanceRepository? repository})
    : _repository = repository ?? TransportMaintenanceRepository();

  // ============================================================
  // STATE
  // ============================================================

  List<TransportMaintenanceModel> _maintenance = [];

  bool _isLoading = false;

  String? _error;

  // ============================================================
  // GETTERS
  // ============================================================

  List<TransportMaintenanceModel> get maintenance =>
      List.unmodifiable(_maintenance);

  bool get isLoading => _isLoading;

  String? get error => _error;

  // ============================================================
  // LOAD ALL
  // ============================================================

  Future<void> loadMaintenance() async {
    _setLoading(true);
    _error = null;

    try {
      _maintenance = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<TransportMaintenanceModel?> getById(int id) async {
    try {
      return await _repository.getById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();

      return null;
    }
  }

  // ============================================================
  // GET BY VEHICLE
  // ============================================================

  Future<List<TransportMaintenanceModel>> getByVehicleId(int vehicleId) async {
    try {
      return await _repository.getByVehicleId(vehicleId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();

      return [];
    }
  }

  // ============================================================
  // ADD
  // ============================================================

  Future<bool> addMaintenance(TransportMaintenanceModel model) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.insert(model);

      _maintenance = await _repository.getAll();

      return true;
    } catch (e) {
      _error = e.toString();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<bool> updateMaintenance(TransportMaintenanceModel model) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.update(model);

      _maintenance = await _repository.getAll();

      return true;
    } catch (e) {
      _error = e.toString();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<bool> deleteMaintenance(int id) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.delete(id);

      _maintenance = await _repository.getAll();

      return true;
    } catch (e) {
      _error = e.toString();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // TOTAL KM
  // ============================================================

  Future<double> getTotalKm() async {
    try {
      return await _repository.getTotalKm();
    } catch (e) {
      _error = e.toString();
      notifyListeners();

      return 0;
    }
  }

  // ============================================================
  // TOTAL DIESEL
  // ============================================================

  Future<double> getTotalDiesel() async {
    try {
      return await _repository.getTotalDiesel();
    } catch (e) {
      _error = e.toString();
      notifyListeners();

      return 0;
    }
  }

  // ============================================================
  // TOTAL DIESEL EXPENSE
  // ============================================================

  Future<double> getTotalDieselExpense() async {
    try {
      return await _repository.getTotalDieselExpense();
    } catch (e) {
      _error = e.toString();
      notifyListeners();

      return 0;
    }
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
