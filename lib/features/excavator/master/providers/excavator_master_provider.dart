import 'package:flutter/foundation.dart';

import '../../../../data/models/excavator_master_model.dart';
import '../../../../data/repositories/excavator_master_repository.dart';

class ExcavatorMasterProvider extends ChangeNotifier {
  final ExcavatorMasterRepository _repository;

  ExcavatorMasterProvider({ExcavatorMasterRepository? repository})
    : _repository = repository ?? ExcavatorMasterRepository();

  // ------------------------------------------------------------
  // STATE
  // ------------------------------------------------------------

  List<ExcavatorMasterModel> _models = [];

  bool _isLoading = false;

  String? _error;

  List<ExcavatorMasterModel> get models => List.unmodifiable(_models);

  bool get isLoading => _isLoading;

  String? get error => _error;

  // ------------------------------------------------------------
  // LOAD ALL MODELS
  // ------------------------------------------------------------

  Future<void> loadModels() async {
    _setLoading(true);
    _clearError();

    try {
      _models = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ------------------------------------------------------------
  // LOAD BY MANUFACTURER
  // ------------------------------------------------------------

  Future<void> loadByManufacturer(int manufacturerId) async {
    _setLoading(true);
    _clearError();

    try {
      _models = await _repository.getByManufacturer(manufacturerId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ------------------------------------------------------------
  // INSERT
  // ------------------------------------------------------------

  Future<bool> addModel(ExcavatorMasterModel model) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.insert(model);
      await loadModels();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ------------------------------------------------------------
  // UPDATE
  // ------------------------------------------------------------

  Future<bool> updateModel(ExcavatorMasterModel model) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.update(model);
      await loadModels();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------

  Future<bool> deleteModel(int id) async {
    _setLoading(true);
    _clearError();

    try {
      await _repository.delete(id);
      await loadModels();
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // ------------------------------------------------------------
  // GET SINGLE MODEL
  // ------------------------------------------------------------

  Future<ExcavatorMasterModel?> getById(int id) async {
    try {
      return await _repository.getById(id);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  void clearError() {
    _clearError();
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
