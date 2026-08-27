import 'package:flutter/foundation.dart';

import '../../../../data/models/transport_master_model.dart';
import '../../../../data/repositories/transport_repository.dart';

class TransportProvider extends ChangeNotifier {
  final TransportRepository _repository;

  TransportProvider({TransportRepository? repository})
    : _repository = repository ?? TransportRepository();

  List<TransportModel> _models = [];

  bool _isLoading = false;
  String? _error;

  List<TransportModel> get models => List.unmodifiable(_models);

  bool get isLoading => _isLoading;

  String? get error => _error;

  // ============================================================
  // LOAD ALL MODELS
  // ============================================================

  Future<void> loadModels() async {
    _setLoading(true);
    _error = null;

    try {
      _models = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOAD BY MANUFACTURER
  // ============================================================

  Future<void> loadByManufacturer(int manufacturerId) async {
    _setLoading(true);
    _error = null;

    try {
      _models = await _repository.getByManufacturer(manufacturerId);
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
  // ADD
  // ============================================================

  Future<bool> addModel(TransportModel model) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.insert(model);
      _models = await _repository.getAll();

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

  Future<bool> updateModel(TransportModel model) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.update(model);
      _models = await _repository.getAll();

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

  Future<bool> deleteModel(int id) async {
    _setLoading(true);
    _error = null;

    try {
      await _repository.delete(id);
      _models = await _repository.getAll();

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
