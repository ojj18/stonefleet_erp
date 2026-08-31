import 'package:flutter/foundation.dart';

import '../../../../data/models/transport_vehicle_model.dart';
import '../../../../data/repositories/transport_vehicle_repository.dart';

class TransportProvider extends ChangeNotifier {
  final TransportRepository _repository;

  TransportProvider({TransportRepository? repository})
    : _repository = repository ?? TransportRepository();

  // ============================================================
  // STATE
  // ============================================================

  List<TransportModel> _vehicles = [];

  bool _isLoading = false;
  String? _error;

  // ============================================================
  // GETTERS
  // ============================================================

  List<TransportModel> get vehicles => List.unmodifiable(_vehicles);

  bool get isLoading => _isLoading;

  String? get error => _error;

  // ============================================================
  // LOAD ALL
  // ============================================================

  Future<void> loadVehicles() async {
    _setLoading(true);
    _error = null;

    try {
      _vehicles = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOAD ACTIVE
  // ============================================================

  Future<void> loadActiveVehicles() async {
    _setLoading(true);
    _error = null;

    try {
      _vehicles = await _repository.getActive();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<TransportModel?> getById(int id) async {
    try {
      return await _repository.getById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ============================================================
  // GET BY REGISTRATION NUMBER
  // ============================================================

  Future<TransportModel?> getByRegistrationNumber(
    String registrationNumber,
  ) async {
    try {
      return await _repository.getByRegistrationNumber(registrationNumber);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ============================================================
  // ADD
  // ============================================================

  Future<bool> addVehicle(TransportModel model) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.insert(model);

      _vehicles = await _repository.getAll();

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

  Future<bool> updateVehicle(TransportModel model) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.update(model);

      _vehicles = await _repository.getAll();

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

  Future<bool> deleteVehicle(int id) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.delete(id);

      _vehicles = await _repository.getAll();

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
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
