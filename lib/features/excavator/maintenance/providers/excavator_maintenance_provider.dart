import 'package:flutter/foundation.dart';

import '../../../../data/models/excavator_maintenance_model.dart';
import '../../../../data/repositories/excavator_maintenance_repository.dart';

class ExcavatorMaintenanceProvider extends ChangeNotifier {
  final ExcavatorMaintenanceRepository _repository;

  ExcavatorMaintenanceProvider({ExcavatorMaintenanceRepository? repository})
    : _repository = repository ?? ExcavatorMaintenanceRepository();

  List<ExcavatorMaintenanceModel> _records = [];

  bool _isLoading = false;
  String? _error;

  List<ExcavatorMaintenanceModel> get records => List.unmodifiable(_records);

  bool get isLoading => _isLoading;

  String? get error => _error;

  // ------------------------------------------------------------
  // LOAD ALL
  // ------------------------------------------------------------

  Future<void> loadMaintenance() async {
    _setLoading(true);
    _error = null;

    try {
      _records = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ------------------------------------------------------------
  // LOAD BY EXCAVATOR
  // ------------------------------------------------------------

  Future<void> loadByExcavator(int excavatorId) async {
    _setLoading(true);
    _error = null;

    try {
      _records = await _repository.getByExcavator(excavatorId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ------------------------------------------------------------
  // ADD
  // ------------------------------------------------------------

  Future<bool> addMaintenance(ExcavatorMaintenanceModel model) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.insert(model);
      _records = await _repository.getAll();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ------------------------------------------------------------
  // UPDATE
  // ------------------------------------------------------------

  Future<bool> updateMaintenance(ExcavatorMaintenanceModel model) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.update(model);
      _records = await _repository.getAll();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------

  Future<bool> deleteMaintenance(int id) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.delete(id);
      _records = await _repository.getAll();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ------------------------------------------------------------
  // GET BY ID
  // ------------------------------------------------------------

  Future<ExcavatorMaintenanceModel?> getById(int id) async {
    try {
      return await _repository.getById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ------------------------------------------------------------
  // COUNT
  // ------------------------------------------------------------

  Future<int> getCount() async {
    try {
      return await _repository.getCount();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
